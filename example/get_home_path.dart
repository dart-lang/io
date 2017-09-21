// Copyright 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:io/io.dart';

void main() {
  print('Home directory: $homePath');
  print('Application data: ${appDataPath('example')}');
}
