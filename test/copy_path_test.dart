// Copyright 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@TestOn('vm')
import 'dart:async';

import 'package:io/io.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:test_descriptor/test_descriptor.dart' as d;

void main() {
  test('should copy a directory (async)', () async {
    await _create();
    await copyPath(p.join(d.sandbox, 'parent'), p.join(d.sandbox, 'copy'));
    await _validate();
  });

  test('should copy a directory (sync)', () async {
    await _create();
    copyPathSync(p.join(d.sandbox, 'parent'), p.join(d.sandbox, 'copy'));
    await _validate();
  });
}

d.DirectoryDescriptor _struct() => d.dir('parent', [
      d.dir('child', [
        d.file('foo.txt'),
      ]),
    ]);
Future _create() => _struct().create();
Future _validate() => _struct().validate();
