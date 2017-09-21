// Copyright 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:path/path.dart' as p;

/// Designated home path for the current user and operating system.
///
/// May be `null` on some platforms. Flutter users should consider using the
/// [path_provider](https://pub.dartlang.org/packages/path_provider) package,
/// which has support for Android and iOS.
String get homePath {
  if (Platform.isMacOS || Platform.isLinux || Platform.isAndroid) {
    // Source: http://en.wikipedia.org/wiki/Home_directory.
    return Platform.environment['HOME'];
  }
  if (Platform.isWindows) {
    // Source: https://en.wikipedia.org/wiki/Special_folder.
    return Platform.environment['UserProfile'];
  }
  return null;
}

/// Returns an application data path for the current user and operating system.
///
/// May return `null` on some platforms without a directory for this purpose.
/// Flutter users should consider using the
/// [path_provider](https://pub.dartlang.org/packages/path_provider) package,
/// which has support for Android and iOS.
String appDataPath(String path) {
  if (Platform.isWindows) {
    return p.join(Platform.environment['APPDATA'], path);
  }
  if (homePath != null) {
    return p.join(homePath, '.$path');
  }
  return null;
}
