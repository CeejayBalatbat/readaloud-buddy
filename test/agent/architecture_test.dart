import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('lib/agent/ is pure Dart: no Flutter imports', () {
    final files = Directory('lib/agent')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'));
    for (final f in files) {
      final src = f.readAsStringSync();
      expect(src, isNot(contains('package:flutter')), reason: f.path);
      expect(src, isNot(contains('dart:ui')), reason: f.path);
    }
  });
}
