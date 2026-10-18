import 'package:flutter_test/flutter_test.dart';
import 'package:readaloud_buddy/agent/agent.dart';

import 'fixtures.dart';

void main() {
  final stories = loadStories();
  const scorer = ReadingScorer();
  double wcpm(double d) => scorer.expectedWcpm(d); // reads at the expected pace

  ReadingCheck check([String language = 'EN']) =>
      ReadingCheck(stories: stories, language: language);

  /// Reads the next passage with [accuracy].
  CheckPassage read(ReadingCheck c, double accuracy) {
    final s = c.nextStory!;
    return c.record(s, accuracy: accuracy, wcpm: wcpm(s.difficulty));
  }

  group('§6 Reading check', () {
    test('passages from books closest to difficulty 15, 40 and 65', () {
      final c = check();
      final ids = <String>[];
      while (!c.isDone) {
        ids.add(c.nextStory!.id);
        read(c, 0.99);
      }
      expect(ids, ['S01', 'S08', 'S12']); // difficulty 18, 39, 58
    });

    test('Filipino readers get Filipino passages', () {
      final c = check('FIL');
      final ids = <String>[];
      while (!c.isDone) {
        ids.add(c.nextStory!.id);
        read(c, 0.99);
      }
      expect(ids, ['S05', 'S09', 'S15']); // difficulty 10, 41, 69
    });

    test('stops at the first Frustration (word accuracy < 90%)', () {
      final c = check();
      read(c, 0.98);
      read(c, 0.85);
      expect(c.isDone, isTrue);
      expect(c.nextStory, isNull);
      expect(() => c.record(stories.first, accuracy: 1, wcpm: 50), throwsStateError);
    });

    test('evidence = difficulty + accuracy + fluency (no questions or mastery)', () {
      final p = read(check(), 0.97);
      expect(p.evidence.comprehensionPart, isNull);
      expect(p.evidence.masteryPart, isNull);
      expect(p.evidence.value, closeTo(18 + 8.75, 1e-9));
    });

    test('start score: last non-Frustration passage and the Frustration one, averaged', () {
      final c = check();
      final ok = read(c, 0.98);
      final hard = read(c, 0.80);
      expect(c.startScore, closeTo((ok.evidence.value + hard.evidence.value) / 2, 1e-9));
    });

    test('start score when every passage went well: the last one', () {
      final c = check();
      read(c, 0.99);
      read(c, 0.99);
      final last = read(c, 0.95);
      expect(c.startScore, last.evidence.value); // S12 (58) at 95%: about 62
      expect(scorer.profileOf(c.startScore), ReadingProfile.transitioning);
    });

    test('start score when the first passage was Frustration: that one', () {
      final c = check();
      final hard = read(c, 0.70);
      expect(c.startScore, hard.evidence.value);
      expect(scorer.profileOf(c.startScore), ReadingProfile.lowEmerging);
    });

    test('closed before any passage: the default (10)', () {
      expect(check().startScore, 10);
    });
  });
}
