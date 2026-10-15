import '../data/story.dart';
import 'agent_config.dart';
import 'hint_ladder.dart';
import 'word_matcher.dart';
import 'word_result.dart';

/// What changed after feeding the tracker a heard word or a clock tick.
class TrackerUpdate {
  const TrackerUpdate({this.finished = const [], this.hint});

  /// Words that just got their final result (to colour them on screen).
  final List<WordOutcome> finished;

  /// A new hint to show/speak, if one became due.
  final Hint? hint;

  static const none = TrackerUpdate();
}

/// Follows one story reading word by word (AGENT_SPEC §1 and §2).
///
/// Pure Dart with no clock of its own: the caller passes the time
/// (elapsed since the story opened) with every call. The UI calls [tick]
/// a few times per second to drive the hint timer, and [onWordHeard] for
/// each new word from the speech recognizer.
class ReadingTracker {
  ReadingTracker({
    required this.words,
    required this.language,
    Duration startedAt = Duration.zero,
    this.config = const AgentConfig(),
    double? hintWaitSec,
    this.startHintLevel = 1,
  })  : hintWaitSec = hintWaitSec ?? config.hintWaitSec,
        _matcher = WordMatcher(config),
        _lastProgressAt = startedAt;

  final List<StoryWord> words;
  final String language;
  final AgentConfig config;
  final double hintWaitSec;

  /// 1 normally, 2 when [HintStats.startLevel] says so.
  final int startHintLevel;

  final WordMatcher _matcher;
  final List<WordOutcome> _outcomes = [];
  final List<HintAttempt> _hintAttempts = [];

  int _index = 0;
  Duration _lastProgressAt; // when the current word became current
  Duration? _lastHintAt;
  int _hintLevel = 0; // hint level reached on the current word
  Duration? _pendingHintAt; // last hint not yet judged a success/failure

  int get currentIndex => _index;
  bool get isFinished => _index >= words.length;
  int get currentHintLevel => _hintLevel;
  List<WordOutcome> get outcomes => List.unmodifiable(_outcomes);

  /// Every hint given and whether it worked, for [HintStats.recordAll].
  List<HintAttempt> get hintAttempts => List.unmodifiable(_hintAttempts);

  /// Feed one recognized word. [confidence] is null when the recognizer
  /// gives none (common for Android partial results).
  TrackerUpdate onWordHeard(String heard, Duration at, {double? confidence}) {
    if (isFinished || WordMatcher.normalize(heard).isEmpty) {
      return TrackerUpdate.none;
    }

    final unsure = confidence == null
        ? config.treatMissingConfidenceAsUnsure
        : confidence < config.asrMinConfidence;
    if (unsure) {
      _dropPendingHint();
      return TrackerUpdate(finished: [_finish(WordResult.unsure, at)]);
    }

    // Look at the current word, then up to `lookAheadWords` further on.
    final last = (_index + config.lookAheadWords).clamp(0, words.length - 1);
    for (var j = _index; j <= last; j++) {
      if (!_matcher.matches(words[j].word, heard, language)) continue;
      final finished = <WordOutcome>[];
      while (_index < j) {
        _closePendingHint(success: false);
        finished.add(_finish(WordResult.skipped, at));
      }
      finished.add(_finish(_matchedResult(at), at));
      return TrackerUpdate(finished: finished);
    }

    _closePendingHint(success: false);
    return TrackerUpdate(finished: [_finish(WordResult.misread, at)]);
  }

  /// Drive the hint ladder. Safe to call as often as you like.
  TrackerUpdate tick(Duration now) {
    final finished = <WordOutcome>[];
    Hint? hint;
    while (!isFinished) {
      final dueAt = (_lastHintAt ?? _lastProgressAt) + _wait;
      if (now < dueAt) break;
      if (_hintLevel == 3) {
        // Whole word was said and still no reading: Buddy moves on.
        _closePendingHint(success: false);
        finished.add(_finish(WordResult.skipped, dueAt));
        continue;
      }
      _closePendingHint(success: false);
      _hintLevel = _hintLevel == 0 ? startHintLevel : _hintLevel + 1;
      _lastHintAt = dueAt;
      _pendingHintAt = dueAt;
      hint = HintLadder.hintFor(words[_index].word, _hintLevel, language);
    }
    return TrackerUpdate(finished: finished, hint: hint);
  }

  /// The child tapped Help: give the next hint step now instead of waiting.
  /// The following step is then due one wait time after this one. Returns
  /// null when the whole word was already given.
  Hint? requestHint(Duration now) {
    if (isFinished || _hintLevel == 3) return null;
    _closePendingHint(success: false);
    _hintLevel = _hintLevel == 0 ? startHintLevel : _hintLevel + 1;
    _lastHintAt = now;
    _pendingHintAt = now;
    return HintLadder.hintFor(words[_index].word, _hintLevel, language);
  }

  /// The hint currently showing for the current word, if any.
  Hint? get currentHint => isFinished || _hintLevel == 0
      ? null
      : HintLadder.hintFor(words[_index].word, _hintLevel, language);

  /// The recognizer stopped on silence and listening restarted. This
  /// deliberately does NOT reset the hint timer (§2).
  void onListeningRestarted(Duration at) {}

  /// The child ended the story early: unread words count as skipped.
  TrackerUpdate finish(Duration at) {
    final finished = <WordOutcome>[];
    while (!isFinished) {
      _closePendingHint(success: false);
      finished.add(_finish(WordResult.skipped, at));
    }
    return TrackerUpdate(finished: finished);
  }

  Duration get _wait =>
      Duration(milliseconds: (hintWaitSec * 1000).round());

  WordResult _matchedResult(Duration at) {
    if (_hintLevel > 0) {
      final success = at - _pendingHintAt! <=
          Duration(milliseconds: (config.hintSuccessWindowSec * 1000).round());
      _closePendingHint(success: success);
      return WordResult.correctAfterHint;
    }
    final waitedMs = (at - _lastProgressAt).inMilliseconds;
    return waitedMs <= config.hesitationSec * 1000
        ? WordResult.correct
        : WordResult.hesitated;
  }

  WordOutcome _finish(WordResult result, Duration at) {
    final w = words[_index];
    final outcome = WordOutcome(
      position: w.position,
      word: w.word,
      patterns: w.patterns,
      primaryPattern: w.primaryPattern,
      result: result,
      responseMs: (at - _lastProgressAt).inMilliseconds,
      hintLevel: _hintLevel,
    );
    _outcomes.add(outcome);
    _index++;
    _lastProgressAt = at;
    _lastHintAt = null;
    _hintLevel = 0;
    return outcome;
  }

  void _closePendingHint({required bool success}) {
    if (_pendingHintAt == null) return;
    _hintAttempts.add(HintAttempt(level: _hintLevel, success: success));
    _pendingHintAt = null;
  }

  /// An unclear word tells us nothing about whether the hint worked.
  void _dropPendingHint() => _pendingHintAt = null;
}
