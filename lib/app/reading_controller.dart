import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../agent/agent.dart';
import '../data/story.dart';
import '../speech/speech_service.dart';

/// Splits a story into pages of whole sentences, about [maxWords] words
/// each. Returns the word indexes (0-based) on each page.
List<List<int>> paginate(List<String> tokens, {int maxWords = 12}) {
  final sentences = <List<int>>[];
  var current = <int>[];
  for (var i = 0; i < tokens.length; i++) {
    current.add(i);
    if (RegExp(r'[.!?]["”’]?$').hasMatch(tokens[i])) {
      sentences.add(current);
      current = [];
    }
  }
  if (current.isNotEmpty) sentences.add(current);

  final pages = <List<int>>[];
  var page = <int>[];
  for (final s in sentences) {
    if (page.isNotEmpty && page.length + s.length > maxWords) {
      pages.add(page);
      page = [];
    }
    page.addAll(s);
  }
  if (page.isNotEmpty) pages.add(page);
  return pages;
}

/// Reading time, which stops while the story is paused. Tests use a
/// [ManualClock] so they can jump ahead in time.
abstract class ReadingClock {
  Duration get elapsed;
  void start();
  void stop();
}

class StopwatchClock implements ReadingClock {
  final _watch = Stopwatch();
  @override
  Duration get elapsed => _watch.elapsed;
  @override
  void start() => _watch.start();
  @override
  void stop() => _watch.stop();
}

class ManualClock implements ReadingClock {
  @override
  Duration elapsed = Duration.zero;
  bool running = false;

  /// Moves time forward (only while running, like a real stopwatch).
  void advance(Duration d) {
    if (running) elapsed += d;
  }

  @override
  void start() => running = true;
  @override
  void stop() => running = false;
}

/// Makes the clock for each reading; tests override it with a ManualClock.
final readingClockProvider =
    Provider<ReadingClock Function()>((ref) => StopwatchClock.new);

/// Runs one read-along: listens through a [SpeechService], feeds words to
/// the agent's [ReadingTracker], drives the hint timer, and keeps track of
/// pages and pause. Screens listen to it and rebuild on [notifyListeners].
class ReadingController extends ChangeNotifier {
  ReadingController({
    required this.story,
    required this.speech,
    List<StoryWord>? words,
    this.config = const AgentConfig(),
    double? hintWaitSec,
    int startHintLevel = 1,
    bool autoHints = true,
    this.tickEvery = const Duration(milliseconds: 200),
    ReadingClock? clock,
  })  : _clock = clock ?? StopwatchClock(),
        words = words ?? story.words,
        hintWaitSec = hintWaitSec ?? config.hintWaitSec {
    final allTokens = story.text.split(RegExp(r'\s+'));
    tokens = [for (final w in this.words) allTokens[w.position - 1]];
    pages = paginate(tokens);
    tracker = ReadingTracker(
      words: this.words,
      language: story.language,
      config: config,
      hintWaitSec: this.hintWaitSec,
      startHintLevel: startHintLevel,
      autoHints: autoHints,
      listensForQuiet: speech.hearsSilence,
      pageStarts: {for (final p in pages) p.first},
    );
  }

  final Story story;
  final SpeechService speech;
  final AgentConfig config;
  final double hintWaitSec;
  final Duration tickEvery;

  /// The words being read (the whole story, or a placement passage).
  final List<StoryWord> words;

  /// Each word as printed, with its punctuation ("strong.").
  late final List<String> tokens;
  late final List<List<int>> pages;
  late final ReadingTracker tracker;

  final ReadingClock _clock;
  Timer? _ticker;
  StreamSubscription<HeardWord>? _sub;
  StreamSubscription<void>? _voiceSub;
  bool _paused = false;
  bool _disposed = false;
  bool _wasQuiet = false;

  /// True when the current hint came from the Help button.
  bool hintFromHelp = false;

  bool get isPaused => _paused;
  bool get isFinished => tracker.isFinished;
  Hint? get hint => tracker.currentHint;
  Duration get elapsed => _clock.elapsed;
  double get readingSeconds => _clock.elapsed.inMilliseconds / 1000;

  List<WordOutcome> get outcomes => tracker.outcomes;

  /// The mic has heard nothing for a while: Buddy asks the child to read
  /// a bit louder, and the hint timer waits.
  bool get isQuiet => !_paused && tracker.isQuiet(_clock.elapsed);

  /// After the whole-word hint Buddy waits; the child can tap "Next word".
  bool get canSkipWord => !_paused && !isFinished && tracker.currentHintLevel == 3;

  /// Result of word [i], or null if it hasn't been read yet.
  WordResult? resultOf(int i) =>
      i < tracker.outcomes.length ? tracker.outcomes[i].result : null;

  int get currentIndex => tracker.currentIndex;

  int get pageIndex {
    if (isFinished) return pages.length - 1;
    return pages.indexWhere((p) => p.contains(currentIndex));
  }

  /// What the microphone is doing (for the mic button).
  MicStatus get micStatus => speech.state.value.status;

  Future<void> start() async {
    _sub = speech.words.listen(_onHeard);
    _voiceSub = speech.voice.listen((_) => _onVoice());
    speech.state.addListener(_notify);
    _expectNext();
    await speech.start(language: story.language);
    _clock.start();
    _ticker = Timer.periodic(tickEvery, (_) => tick());
    _notify();
  }

  /// Tapping the mic after a problem (e.g. permission): try again.
  void retryMic() {
    if (_paused || isFinished) return;
    speech.start(language: story.language);
  }

  void pause() {
    if (_paused || isFinished) return;
    _paused = true;
    _clock.stop();
    speech.stop();
    _notify();
  }

  void resume() {
    if (!_paused || isFinished) return;
    _paused = false;
    _clock.start();
    speech.start(language: story.language);
    _notify();
  }

  /// The Help button: next hint step right away. Returns false when the
  /// whole word is already showing (the screen then says it again).
  bool help() {
    if (_paused || isFinished) return false;
    if (tracker.requestHint(_clock.elapsed) == null) return false;
    hintFromHelp = true;
    _notify();
    return true;
  }

  /// The "Next word" button after the whole-word hint: skip this word.
  void nextWord() {
    if (!canSkipWord) return;
    tracker.skipWord(_clock.elapsed);
    _afterProgress();
  }

  /// Ends the reading early: unread words count as skipped.
  void finishEarly() {
    tracker.finish(_clock.elapsed);
    _stop();
    _notify();
  }

  void _onHeard(HeardWord w) {
    if (_paused || isFinished) return;
    final update =
        tracker.onWordHeard(w.text, _clock.elapsed, confidence: w.confidence);
    if (update.finished.isNotEmpty) {
      _afterProgress();
    } else {
      _notifyIfQuietChanged();
    }
  }

  void _onVoice() {
    if (_paused || isFinished) return;
    tracker.onSpeech(_clock.elapsed);
    _notifyIfQuietChanged();
  }

  /// Drives the hint timer; called every [tickEvery] by a timer.
  @visibleForTesting
  void tick() {
    if (_paused || isFinished) return;
    final hadHint = tracker.currentHintLevel;
    final update = tracker.tick(_clock.elapsed);
    if (update.hint != null) hintFromHelp = false;
    if (tracker.currentHintLevel != hadHint) {
      _notify();
    } else {
      _notifyIfQuietChanged();
    }
  }

  void _notifyIfQuietChanged() {
    if (isQuiet != _wasQuiet) _notify();
  }

  void _expectNext() =>
      speech.expectedWord = isFinished ? null : words[currentIndex].word;

  void _afterProgress() {
    _expectNext();
    hintFromHelp = false;
    if (isFinished) _stop();
    _notify();
  }

  void _stop() {
    _clock.stop();
    _ticker?.cancel();
    speech.stop();
  }

  void _notify() {
    _wasQuiet = isQuiet;
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _ticker?.cancel();
    _sub?.cancel();
    _voiceSub?.cancel();
    speech.state.removeListener(_notify);
    speech.stop();
    super.dispose();
  }
}
