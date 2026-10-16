import 'package:flutter_test/flutter_test.dart';
import 'package:readaloud_buddy/speech/speech_timing.dart';

Duration ms(int v) => Duration(milliseconds: v);

void main() {
  test('a pause then loud again is a new onset', () {
    final t = SpeechTimer();
    t.soundLevel(6, ms(0)); // "Sam"
    t.soundLevel(6, ms(200));
    t.soundLevel(0, ms(400));
    t.soundLevel(6, ms(1000)); // pause of 800 ms, then "has"
    t.result(1, ms(1500));
    expect(t.passedOn(0, 'has', ms(1500)).recognizerMs, 500);
  });

  test('without any loud sound the recognizer time is unknown', () {
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
      t.soundLevel(6, ms(i * 10000));
      t.result(1, ms(i * 10000 + 100 * (i + 1)));
      t.passedOn(0, 'w$i', ms(i * 10000 + 100 * (i + 1)));
      t.painted(ms(i * 10000 + 100 * (i + 1) + 20));
    }
    final s = t.summary();
    expect(s.words, 3);
    expect(s.recognizerMs, 400); // of 300, 400, 500
    expect(s.screenMs, 20);
    expect(s.last, contains('"w4"'));
  });
}
