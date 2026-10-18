/// How long one word took from the child's voice to the screen.
///
///   said ──recognizer──▶ first in a result ──settling──▶ passed on
///        ──screen──▶ next frame drawn
class WordTiming {
  WordTiming({
    required this.word,
    this.recognizerMs,
    required this.settlingMs,
    required this.passedOnAt,
  });

  final String word;
  final Duration passedOnAt;

  /// From when the word was said until it first showed up in a recognizer
  /// result: the word's own start time in Vosk's audio, filled in by
  /// [SpeechTimer.spokenAt] when the utterance's final result arrives.
  /// null until then.
  int? recognizerMs;

  /// Already printed to the console.
  bool reported = false;

  /// From first showing up until we passed it on: 0 when it was accepted
  /// from a partial result; longer when we waited for it to stop changing.
  final int settlingMs;

  /// From passed on until the next frame was drawn.
  int? screenMs;

  int? get totalMs => recognizerMs == null || screenMs == null
      ? null
      : recognizerMs! + settlingMs + screenMs!;

  @override
  String toString() => '"$word": recognizer ${recognizerMs ?? '?'} ms'
      ' + settling $settlingMs ms + screen ${screenMs ?? '?'} ms'
      ' = ${totalMs ?? '?'} ms';
}

/// Medians over the last words, for Buddy's brain.
class SpeedSummary {
  const SpeedSummary({
    required this.words,
    this.recognizerMs,
    this.settlingMs,
    this.screenMs,
    this.totalMs,
    this.last,
  });

  final int words;
  final int? recognizerMs;
  final int? settlingMs;
  final int? screenMs;
  final int? totalMs;
  final String? last;
}

/// Measures speech-to-screen delay (pure Dart; the caller passes times).
class SpeechTimer {
  SpeechTimer({this.keep = 30});

  /// How many recent words the summary uses.
  final int keep;

  final _firstSeen = <int, Duration>{}; // word position → first seen
  final _utterance = <int, WordTiming>{}; // word position → its timing
  final _samples = <WordTiming>[];

  List<WordTiming> get samples => List.unmodifiable(_samples);

  /// A new utterance starts (word positions count from 0 again).
  void newUtterance() {
    _firstSeen.clear();
    _utterance.clear();
  }

  /// Word [index] of the utterance started at [at] (Vosk word timestamps):
  /// sets its recognizer time exactly.
  void spokenAt(int index, Duration at) {
    final t = _utterance[index], seen = _firstSeen[index];
    if (t == null || seen == null) return;
    final ms = (seen - at).inMilliseconds;
    t.recognizerMs = ms < 0 ? 0 : ms;
  }

  /// Words with every part measured that weren't printed yet (marks them).
  List<WordTiming> takeComplete() => [
        for (final t in _samples)
          if (!t.reported && t.totalMs != null) t..reported = true,
      ];

  /// A recognizer result with [count] words arrived.
  void result(int count, Duration at) {
    for (var i = 0; i < count; i++) {
      _firstSeen.putIfAbsent(i, () => at);
    }
  }

  /// Word [index] of the utterance was passed on to the reading screen.
  WordTiming passedOn(int index, String word, Duration at) {
    final seen = _firstSeen[index] ?? at;
    final t = WordTiming(
      word: word,
      settlingMs: (at - seen).inMilliseconds,
      passedOnAt: at,
    );
    _samples.add(t);
    _utterance[index] = t;
    if (_samples.length > keep) _samples.removeAt(0);
    return t;
  }

  /// The next frame was drawn: fills in screen time for waiting words.
  /// Returns the words that just got complete.
  List<WordTiming> painted(Duration at) {
    final done = <WordTiming>[];
    for (final t in _samples) {
      if (t.screenMs == null) {
        t.screenMs = (at - t.passedOnAt).inMilliseconds;
        done.add(t);
      }
    }
    return done;
  }

  SpeedSummary summary() => SpeedSummary(
        words: _samples.length,
        recognizerMs: _median([for (final t in _samples) t.recognizerMs]),
        settlingMs: _median([for (final t in _samples) t.settlingMs]),
        screenMs: _median([for (final t in _samples) t.screenMs]),
        totalMs: _median([for (final t in _samples) t.totalMs]),
        last: _samples.isEmpty ? null : _samples.last.toString(),
      );

  static int? _median(List<int?> values) {
    final v = [for (final x in values) ?x]..sort();
    return v.isEmpty ? null : v[v.length ~/ 2];
  }
}
