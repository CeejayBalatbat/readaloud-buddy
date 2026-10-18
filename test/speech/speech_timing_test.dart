import 'package:flutter_test/flutter_test.dart';
import 'package:readaloud_buddy/speech/speech_timing.dart';

Duration ms(int v) => Duration(milliseconds: v);

void main() {
  test('Vosk word start times set the recognizer time exactly', () {
    final t = SpeechTimer();
    t.result(2, ms(1500)); // "sam has" first seen at 1.5 s
    final sam = t.passedOn(0, 'sam', ms(1500));
    final has = t.passedOn(1, 'has', ms(1600));
    expect(sam.recognizerMs, isNull); // until the final result says when
    t.spokenAt(0, ms(1000));
    t.spokenAt(1, ms(1300));
    expect(sam.recognizerMs, 500);
    expect(has.recognizerMs, 200);
    expect(has.settlingMs, 100);
  });

  test('without word times the recognizer time is unknown', () {
    final t = SpeechTimer();
    t.result(1, ms(500));
    final w = t.passedOn(0, 'cat', ms(500));
    expect(w.recognizerMs, isNull);
    expect(w.totalMs, isNull);
  });

  test('summary gives medians and keeps only the last words', () {
    final t = SpeechTimer(keep: 3);
    for (var i = 0; i < 5; i++) {
      t.newUtterance();
      t.result(1, ms(i * 10000 + 100 * (i + 1)));
      t.passedOn(0, 'w$i', ms(i * 10000 + 100 * (i + 1)));
      t.spokenAt(0, ms(i * 10000));
      t.painted(ms(i * 10000 + 100 * (i + 1) + 20));
    }
    final s = t.summary();
    expect(s.words, 3);
    expect(s.recognizerMs, 400); // of 300, 400, 500
    expect(s.screenMs, 20);
    expect(s.last, contains('"w4"'));
  });
}
