import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:readaloud_buddy/data/story.dart';

void main() {
  late List<Story> stories;

  setUpAll(() {
    stories = parseStories(File('assets/data/stories.json').readAsStringSync());
  });

  test('loads all 20 stories', () {
    expect(stories, hasLength(20));
    expect(stories.first.title, 'Sam and the Cat');
  });

  test('every story has a valid level, language and tagged words', () {
    for (final s in stories) {
      expect(s.level, inInclusiveRange(1, 4), reason: s.id);
      expect(s.language, anyOf('EN', 'FIL'), reason: s.id);
      expect(s.words, isNotEmpty, reason: s.id);
      for (final w in s.words) {
        expect(
          w.patterns,
          contains(w.primaryPattern),
          reason: '${s.id} ${w.word}',
        );
      }
    }
  });

  test('every question has 3 choices with exactly one correct, matching the answer', () {
    for (final s in stories) {
      expect(s.questions, hasLength(3), reason: s.id);
      for (final q in s.questions) {
        expect(q.choices, hasLength(3), reason: q.id);
        final correct = q.choices.where((c) => c.correct).toList();
        expect(correct, hasLength(1), reason: q.id);
        expect(correct.single.text, q.answer, reason: q.id);
      }
    }
  });
}
