/// Every tunable number the agent uses, in one place (AGENT_SPEC.md).
///
/// Use `const AgentConfig()` for the defaults. Tests (or a future settings
/// screen) can override single values, e.g. `AgentConfig(framesToMoveDown: 2)`.
class AgentConfig {
  const AgentConfig({
    // §1 Word results
    this.hesitationSec = 3,
    this.asrMinConfidence = 0.5,
    this.treatMissingConfidenceAsUnsure = false,
    this.lookAheadWords = 2,
    this.enMinLettersForTypoTolerance = 5,
    this.enMaxEditDistance = 1,
    this.filMaxEditDistance = 0,
    // §2 Hint ladder
    this.hintWaitSec = 5,
    this.dyslexiaHintWaitSec = 8,
    this.hintSuccessWindowSec = 5,
    this.hintLearningMinUses = 10,
    this.hintLevel2SuccessMin = 0.70,
    this.hintLevel1SuccessMax = 0.40,
    // §4 Phil-IRI thresholds (lower bounds)
    this.independentAccuracy = 0.97,
    this.instructionalAccuracy = 0.90,
    this.independentComprehension = 0.80,
    this.instructionalComprehension = 0.59,
    // §5 Level decisions
    this.minLevel = 1,
    this.maxLevel = 4,
    this.framesToMoveUp = 2,
    this.framesToMoveDown = 1,
    // §6 Placement
    this.placementMaxLevel = 3,
    // §7 Bayesian Knowledge Tracing
    this.bktP0 = 0.35,
    this.bktLearn = 0.12,
    this.bktSlip = 0.08,
    this.bktGuess = 0.20,
    this.masteredMin = 0.85,
    this.learningMin = 0.50,
    // §8 Tricky words
    this.trickyCleanReadsToRemove = 2,
    // §9 Story selection
    this.shelfSize = 4,
    this.recentSessionsWindow = 3,
    this.recentlyReadPenalty = 1.0,
    this.maxRandomBonus = 0.15,
    this.commonPatterns = const {'EN-SW', 'EN-SV', 'FIL-SW', 'FIL-CV'},
    // §10 Teacher flag
    this.flagWindowSessions = 3,
    this.flagFrustrationCount = 2,
    this.flagNeedsHelpAfterSessions = 3,
  });

  final double hesitationSec;
  final double asrMinConfidence;
  final bool treatMissingConfidenceAsUnsure;
  final int lookAheadWords;
  final int enMinLettersForTypoTolerance;
  final int enMaxEditDistance;
  final int filMaxEditDistance;

  final double hintWaitSec;
  final double dyslexiaHintWaitSec;
  final double hintSuccessWindowSec;
  final int hintLearningMinUses;
  final double hintLevel2SuccessMin;
  final double hintLevel1SuccessMax;

  final double independentAccuracy;
  final double instructionalAccuracy;
  final double independentComprehension;
  final double instructionalComprehension;

  final int minLevel;
  final int maxLevel;
  final int framesToMoveUp;
  final int framesToMoveDown;

  final int placementMaxLevel;

  final double bktP0;
  final double bktLearn;
  final double bktSlip;
  final double bktGuess;
  final double masteredMin;
  final double learningMin;

  final int trickyCleanReadsToRemove;

  final int shelfSize;
  final int recentSessionsWindow;
  final double recentlyReadPenalty;
  final double maxRandomBonus;

  /// Tags found in almost every story (sight words, short vowels, simple
  /// syllables). Only used to pick which sound the shelf reason names.
  final Set<String> commonPatterns;

  final int flagWindowSessions;
  final int flagFrustrationCount;
  final int flagNeedsHelpAfterSessions;

  /// Seconds to wait before each hint step. A parent-set value wins;
  /// otherwise dyslexia mode uses the longer wait.
  double hintWaitFor({bool dyslexiaMode = false, double? parentSetSec}) =>
      parentSetSec ?? (dyslexiaMode ? dyslexiaHintWaitSec : hintWaitSec);
}
