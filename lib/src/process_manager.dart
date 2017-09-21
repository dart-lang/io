// Copyright 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io' as io;

import 'package:meta/meta.dart';

import 'shared_stdin.dart';

/// A high-level abstraction around using and managing processes on the system.
abstract class ProcessManager {
  /// Terminates the global `stdin` listener, making future listens impossible.
  ///
  /// This method should be invoked only at the _end_ of a program's execution.
  static Future<Null> terminateStdIn() async {
    await sharedStdIn.terminate();
  }

  /// Create a new instance of [ProcessManager] for the current platform.
  ///
  /// May manually specify whether the current platform [isWindows], otherwise
  /// this is derived from the Dart runtime (i.e. [io.Platform.isWindows]).
  factory ProcessManager({
    Stream<List<int>> stdin,
    io.IOSink stdout,
    io.IOSink stderr,
    bool isWindows,
  }) {
    stdin ??= sharedStdIn;
    stdout ??= io.stdout;
    stderr ??= io.stderr;
    isWindows ??= io.Platform.isWindows;
    if (isWindows) {
      return new _WindowsProcessManager(stdin, stdout, stderr);
    }
    return new _UnixProcessManager(stdin, stdout, stderr);
  }

  /// Create a new instance of [ProcessManager] for the current platform.
  ///
  /// May manually specify whether the current platform [isWindows], otherwise
  /// this is derived from the Dart runtime (i.e. [io.Platform.isWindows]).
  ///
  /// The `stdin` stream does _not_ forward on [spawn].
  factory ProcessManager.background({
    io.IOSink stdout,
    io.IOSink stderr,
    bool isWindows,
  }) {
    return new ProcessManager(
      stdin: const Stream.empty(),
      isWindows: isWindows,
    );
  }

  /// Create a new instance of [ProcessManager] for the current platform.
  ///
  /// May manually specify whether the current platform [isWindows], otherwise
  /// this is derived from the Dart runtime (i.e. [io.Platform.isWindows]).
  ///
  /// Standard streams I/O (stdin, stdout, stderr) are not forwarded on [spawn].
  factory ProcessManager.headless({bool isWindows}) {
    return new ProcessManager(
      stdin: const Stream.empty(),
      stdout: new io.IOSink(const _NullStreamConsumer()),
      stderr: new io.IOSink(const _NullStreamConsumer()),
      isWindows: isWindows,
    );
  }

  final Stream<List<int>> _stdin;
  final io.IOSink _stdout;
  final io.IOSink _stderr;

  const ProcessManager._(this._stdin, this._stdout, this._stderr);

  /// Spawns a process by invoking [executable] with [arguments].
  ///
  /// This is _similar_ to [io.Process.start], but all standard input and output
  /// is forwarded/routed between the process and the host, similar to how a
  /// shell script works.
  ///
  /// Returns a future that completes with a handle to the spawned process.
  Future<io.Process> spawn(
    String executable, {
    Iterable<String> arguments: const [],
  }) async {
    final process = io.Process.start(executable, arguments.toList());
    return new _ForwardingSpawn(await process, _stdin, _stdout, _stderr);
  }
}

class _NullStreamConsumer<T> implements StreamConsumer<T> {
  const _NullStreamConsumer();

  @override
  Future addStream(Stream<T> stream) => new Future<dynamic>.value();

  @override
  Future close() => new Future<dynamic>.value();
}

/// A process instance created and managed through [ProcessManager].
///
/// Unlike one created directly by [io.Process.start] or [io.Process.run], a
/// spawned process works more like executing a command in a shell script.
class Spawn implements io.Process {
  final io.Process _delegate;

  Spawn._(this._delegate) {
    _delegate.exitCode.then((_) => _onClosed());
  }

  @mustCallSuper
  void _onClosed() {}

  @override
  bool kill([io.ProcessSignal signal = io.ProcessSignal.SIGTERM]) =>
      _delegate.kill(signal);

  @override
  Future<int> get exitCode => _delegate.exitCode;

  @override
  int get pid => _delegate.pid;

  @override
  Stream<List<int>> get stderr => _delegate.stderr;

  @override
  io.IOSink get stdin => _delegate.stdin;

  @override
  Stream<List<int>> get stdout => _delegate.stdout;
}

/// Forwards `stdin`/`stdout`/`stderr` to/from the host.
class _ForwardingSpawn extends Spawn {
  final StreamSubscription _stdInSub;
  final StreamSubscription _stdOutSub;
  final StreamSubscription _stdErrSub;
  final StreamController<List<int>> _stdOut;
  final StreamController<List<int>> _stdErr;

  factory _ForwardingSpawn(
    io.Process delegate,
    Stream<List<int>> stdin,
    io.IOSink stdout,
    io.IOSink stderr,
  ) {
    final stdoutSelf = new StreamController<List<int>>();
    final stderrSelf = new StreamController<List<int>>();
    final stdInSub = stdin.listen(delegate.stdin.add);
    final stdOutSub = delegate.stdout.listen((event) {
      stdout.add(event);
      stdoutSelf.add(event);
    });
    final stdErrSub = delegate.stderr.listen((event) {
      stderr.add(event);
      stderrSelf.add(event);
    });
    return new _ForwardingSpawn._delegate(
      delegate,
      stdInSub,
      stdOutSub,
      stdErrSub,
      stdoutSelf,
      stderrSelf,
    );
  }

  _ForwardingSpawn._delegate(
    io.Process delegate,
    this._stdInSub,
    this._stdOutSub,
    this._stdErrSub,
    this._stdOut,
    this._stdErr,
  )
      : super._(delegate);

  @override
  void _onClosed() {
    _stdInSub.cancel();
    _stdOutSub.cancel();
    _stdErrSub.cancel();
    super._onClosed();
  }

  @override
  Stream<List<int>> get stdout => _stdOut.stream;

  @override
  Stream<List<int>> get stderr => _stdErr.stream;
}

class _UnixProcessManager extends ProcessManager {
  const _UnixProcessManager(
    Stream<List<int>> stdin,
    io.IOSink stdout,
    io.IOSink stderr,
  )
      : super._(
          stdin,
          stdout,
          stderr,
        );
}

class _WindowsProcessManager extends ProcessManager {
  const _WindowsProcessManager(
    Stream<List<int>> stdin,
    io.IOSink stdout,
    io.IOSink stderr,
  )
      : super._(
          stdin,
          stdout,
          stderr,
        );
}
