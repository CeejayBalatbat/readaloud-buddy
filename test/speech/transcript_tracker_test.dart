import 'package:flutter_test/flutter_test.dart';
import 'package:readaloud_buddy/speech/transcript_tracker.dart';

void main() {
  late TranscriptTracker t;
  late List<String> out;

  setUp(() {
    t = TranscriptTracker();
    out = [];
  });

  void feed(String text, {bool isFinal = false, String? expect, bool muted = false}) =>
      t.update(text,
          isFinal: isFinal,
          emit: out.add,
          acceptEarly: expect == null ? null : (w) => w.toLowerCase() == expect,
          muted: muted);

  test('words before the last one are passed on as they appear', () {
    feed('Sam');
    expect(out, isEmpty); // last word may still change
    feed('Sam has');
    expect(out, ['Sam']);
    feed('Sam has a cat');
    expect(out, ['Sam', 'has', 'a']);
  });

  test('a final result passes on the rest', () {
    feed('Sam has');
    feed('Sam has a', isFinal: true);
    expect(out, ['Sam', 'has', 'a']);
  });

  test('the last word is passed on early when it matches the expected word',
      () {
    feed('Sam', expect: 'sam');
    expect(out, ['Sam']);
    feed('Sam has', expect: 'cat'); // "has" not expected: wait
    expect(out, ['Sam']);
  });

  test('each word position is passed on only once, even if revised', () {
    feed('the cat', expect: 'cat');
    expect(out, ['the', 'cat']);
    feed('the cats sat', isFinal: true);
    expect(out, ['the', 'cat', 'sat']);
  });

  test('a shorter revision adds nothing', () {
    feed('a big red');
    feed('a big', isFinal: true);
    expect(out, ['a', 'big']);
  });

  test('reset starts a new utterance after a restart', () {
    feed('Sam has', isFinal: true);
    t.reset();
    feed('a cat', isFinal: true);
    expect(out, ['Sam', 'has', 'a', 'cat']);
  });

  test('while muted (Buddy speaking) heard words are skipped for good', () {
    feed('thr ough', muted: true);
    feed('thr ough through', isFinal: true);
    expect(out, ['through']);
  });

  test('digits become words', () {
    feed('I have 2 cats', isFinal: true);
    expect(out, ['I', 'have', 'two', 'cats']);
  });
}
