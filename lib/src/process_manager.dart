// Copyright 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io' as io;

import 'package:async/async.dart';
import 'package:meta/meta.dart';

/// A global StreamQueue for `stdin`.
///
/// This allows different spawned processes to share the same listener to stdin
/// without dropping data on the floor, assuming there is only a single spawned
/// process using stdin at a time.
StreamQueue<List<int>> get _stdInAsQueue {
  // TODO: It would be beneficial to have a locking/release mechanism for this.
  return _stdInQueue ??= new StreamQueue<List<int>>(io.stdin);
}

StreamQueue<List<int>> _stdInQueue;

/// A high-level abstraction around using and managing processes on the system.
abstract class ProcessManager {
  /// Terminates the global `stdin` listener, making future listens impossible.
  ///
  /// This method should be invoked only at the _end_ of a program's execution.
  static Future<Null> terminateStdIn() async {
    await _stdInQueue?.cancel(immediate: true);
  }

  /// Create a new instance of [ProcessManager] for the current platform.
  ///
  /// May manually specify whether the current platform [isWindows], otherwise
  /// this is derived from the Dart runtime (i.e. [io.Platform.isWindows]).
  factory ProcessManager({bool isWindows}) {
    if (isWindows ?? io.Platform.isWindows) {
      return const _WindowsProcessManager();
    }
    return const _UnixProcessManager();
  }

  /// Prevents sub-classing until this class is stable.
  const ProcessManager._();

  /// Spawns a process by invoking [executable] with [arguments].
  ///
  /// This is _similar_ to [io.Process.start], but all standard input and output
  /// is forwarded/routed between the process and the host, similar to how a
  /// bash or shell script works.
  ///
  /// Returns a future that completes with a handle to the spawned process.
  Future<io.Process> spawn(
    String executable, {
    Iterable<String> arguments: const [],
  }) async {
    final process = io.Process.start(executable, arguments.toList());
    return new _ForwardingSpawn(await process);
  }
}

/// A process instance created and managed through [ProcessManager].
///
/// Unlike one created directly by [io.Process.start] or [io.Process.run], a
/// spawned process works more like executing a command in a shell or bash
/// script, where stdin/out/err are bound together with the host process until
/// complete.
class Spawn implements io.Process {
  final io.Process _delegate;

  bool _isClosed = false;

  Spawn._(this._delegate) {
    _delegate.exitCode.then((_) => _onClosed());
  }

  @mustCallSuper
  @visibleForOverriding
  void _onClosed() {
    _isClosed = true;
  }

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
  final StreamSubscription _stdOutSub;
  final StreamSubscription _stdErrSub;

  factory _ForwardingSpawn(io.Process delegate) {
    final stdOutSub = delegate.stdout.listen(io.stdout.add);
    final stdErrSub = delegate.stderr.listen(io.stdout.add);
    return new _ForwardingSpawn._delegate(
      delegate,
      stdOutSub,
      stdErrSub,
    );
  }

  _ForwardingSpawn._delegate(
    io.Process delegate,
    this._stdOutSub,
    this._stdErrSub,
  )
      : super._(delegate) {
    scheduleMicrotask(() async {
      while (!_isClosed && await _stdInAsQueue.hasNext) {
        delegate.stdin.add(await _stdInAsQueue.next);
      }
    });
  }

  @override
  void _onClosed() {
    _stdOutSub.cancel();
    _stdErrSub.cancel();
    super._onClosed();
  }
}

class _UnixProcessManager extends ProcessManager {
  const _UnixProcessManager() : super._();
}

class _WindowsProcessManager extends ProcessManager {
  const _WindowsProcessManager() : super._();
}
