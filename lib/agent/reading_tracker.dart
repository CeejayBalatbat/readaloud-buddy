import '../data/story.dart';
import 'agent_config.dart';
import 'hint_ladder.dart';
import 'phonics.dart';
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
/// a few times per second to drive the hint timer, [onWordHeard] for each
/// new word from the speech recognizer, and [onSpeech] whenever the
/// recognizer hears the child's voice at all (matching or not).
///
/// The hint timer only counts while the child is stuck, not while the
/// microphone simply hears nothing (§2 "When the hint timer counts").
class ReadingTracker {
  ReadingTracker({
    required this.words,
    required this.language,
    Duration startedAt = Duration.zero,
    this.config = const AgentConfig(),
    double? hintWaitSec,
    this.startHintLevel = 1,
    this.autoHints = true,
    this.listensForQuiet = true,
    this.pageStarts = const {0},
    this.phonics = PhonicsDictionary.empty,
    this.storyId,
  })  : hintWaitSec = hintWaitSec ?? config.hintWaitSec,
        _matcher = WordMatcher(config),
        _lastProgressAt = startedAt,
        _lastSpeechAt = startedAt,
        _countedTo = startedAt;

  final List<StoryWord> words;
  final String language;
  final AgentConfig config;
  final double hintWaitSec;

  /// 1 normally, 2 when [HintStats.startLevel] says so.
  final int startHintLevel;

  /// false = the parent chose "Only when I tap Help": no timed hints.
  final bool autoHints;

  /// true with a real microphone. false for tap-to-read, where there is no
  /// voice to listen for, so silence never pauses the timer. Can change
  /// mid-story (the microphone failed and the story switched to tapping).
  bool listensForQuiet;

  /// Indexes (into [words]) of the first word on each page. These words
  /// are never timed.
  final Set<int> pageStarts;

  /// English phonics data (keywords, sight words) for the hints.
  final PhonicsDictionary phonics;

  /// For words read two ways in one story (phonics.json "occurrences").
  final String? storyId;

  String? get _occurrence =>
      storyId == null || isFinished ? null : '$storyId:${words[_index].position}';

  final WordMatcher _matcher;
  final List<WordOutcome> _outcomes = [];
  final List<HintAttempt> _hintAttempts = [];

  int _index = 0;
  Duration _lastProgressAt; // when the current word became current
  int _hintLevel = 0; // hint level reached on the current word
  Duration? _pendingHintAt; // last hint not yet judged a success/failure
  Duration _lastSpeechAt; // the child's voice was last heard here
  Duration _countedTo; // hint time has been counted up to here
  Duration _stuck = Duration.zero; // counted time since the word/last hint

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
    onSpeech(at);

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

  /// The recognizer heard the child's voice (any speech, even if it is not
  /// a whole word yet or not the right word). Keeps the hint timer going.
  void onSpeech(Duration at) {
    _countTo(at, giveHints: false);
    if (at > _lastSpeechAt) _lastSpeechAt = at;
  }

  /// Drive the hint ladder. Safe to call as often as you like. Never moves
  /// past a word: after the whole word (level 3) Buddy waits for the child
  /// or for [skipWord].
  TrackerUpdate tick(Duration now) => TrackerUpdate(hint: _countTo(now));

  /// True when the microphone has heard no speech for a while: the hint
  /// timer is paused and Buddy asks the child to read a bit louder.
  bool isQuiet(Duration now) =>
      listensForQuiet && !isFinished && now - _lastSpeechAt >= _quietAfter;

  /// The child tapped Help: give the next hint step now instead of waiting.
  /// Works on any word, also when hints are Help-only or the mic hears
  /// nothing. The following step is then due one wait time after this one.
  /// Returns null when the whole word was already given.
  Hint? requestHint(Duration now) {
    _countTo(now, giveHints: false);
    if (isFinished || _hintLevel == 3) return null;
    return _giveHint(now);
  }

  /// The child tapped "Next word" (shown after the whole-word hint): the
  /// word counts as skipped and reading goes on.
  TrackerUpdate skipWord(Duration at) {
    _countTo(at, giveHints: false);
    if (isFinished) return TrackerUpdate.none;
    _closePendingHint(success: false);
    return TrackerUpdate(finished: [_finish(WordResult.skipped, at)]);
  }

  /// The hint currently showing for the current word, if any.
  Hint? get currentHint => isFinished || _hintLevel == 0
      ? null
      : HintLadder.hintFor(words[_index].word, _hintLevel, language, phonics: phonics, occurrence: _occurrence);

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

  Duration get _wait => _dur(hintWaitSec);

  Duration get _quietAfter =>
      _dur(config.noSpeechSec > hintWaitSec ? config.noSpeechSec : hintWaitSec);

  static Duration _dur(double sec) =>
      Duration(milliseconds: (sec * 1000).round());

  /// Whether stuck time counts on the current word at all.
  bool get _timed =>
      autoHints && !isFinished && _hintLevel < 3 && !pageStarts.contains(_index);

  /// Adds the time between the last call and [now] that counts toward a
  /// hint. Time counts only on a [_timed] word, and only until no speech
  /// has been heard for a while (when there is a microphone to listen
  /// with). With [giveHints] the hints that became due are given;
  /// otherwise a due hint waits for the next [tick], so the UI shows every
  /// hint before the tracker counts it.
  Hint? _countTo(Duration now, {bool giveHints = true}) {
    var from = _countedTo;
    if (now > _countedTo) _countedTo = now;
    if (!_timed) return null;
    var to = now;
    if (listensForQuiet) {
      final quietAt = _lastSpeechAt + _quietAfter;
      if (quietAt < to) to = quietAt;
    }
    if (to < from) to = from; // nothing new to count
    Hint? hint;
    while (_hintLevel < 3) {
      final due = from + (_wait - _stuck);
      if (due > to) {
        _stuck += to - from;
        break;
      }
      if (!giveHints) {
        _stuck = _wait; // due now; the next tick gives it
        break;
      }
      hint = _giveHint(due);
      from = due;
    }
    return hint;
  }

  Hint _giveHint(Duration at) {
    _closePendingHint(success: false);
    // Sight words have one hint only: the whole word (level 3).
    _hintLevel = HintLadder.isSight(words[_index].word, language, phonics)
        ? 3
        : _hintLevel == 0
            ? startHintLevel
            : _hintLevel + 1;
    _pendingHintAt = at;
    _stuck = Duration.zero;
    return HintLadder.hintFor(words[_index].word, _hintLevel, language, phonics: phonics, occurrence: _occurrence);
  }

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
    _stuck = Duration.zero;
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
