// Copyright 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

// TODO: Change to io.dart once this feature is published.
import 'package:io/src/process_manager.dart';

/// Runs `dartfmt` and `pub` via [ProcessManager.spawn] as an example.
Future<Null> main() async {
  final manager = new ProcessManager();
  print('Running dartfmt --version');
  var spawn = await manager.spawn('dartfmt', arguments: ['--version']);
  await spawn.exitCode;
  print('Running dartfmt -n .');
  spawn = await manager.spawn('dartfmt', arguments: ['-n', '.']);
  await spawn.exitCode;
  print('Running pub publish');
  spawn = await manager.spawn('pub', arguments: ['pub', 'publish']);
  await ProcessManager.terminateStdIn();
}
