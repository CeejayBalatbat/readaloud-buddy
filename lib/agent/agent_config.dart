/// Every tunable number the agent uses, in one place (AGENT_SPEC.md).
///
/// Use `const AgentConfig()` for the defaults. Tests (or a future settings
/// screen) can override single values, e.g. `AgentConfig(developingMin: 45)`.
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
    this.filSpellingVariants = true,
    // Speech: when the big Filipino model is too heavy for the phone
    this.filMinFreeMemoryMb = 1200,
    this.filMaxLoadSeconds = 60,
    this.filMaxRecognizerMs = 2500,
    // §2 Hint ladder
    this.hintWaitSec = 5,
    this.dyslexiaHintWaitSec = 8,
    this.noSpeechSec = 8,
    this.hintSuccessWindowSec = 5,
    this.hintLearningMinUses = 10,
    this.hintLevel2SuccessMin = 0.70,
    this.hintLevel1SuccessMax = 0.40,
    // §4 Phil-IRI thresholds (lower bounds)
    this.independentAccuracy = 0.97,
    this.instructionalAccuracy = 0.90,
    this.independentComprehension = 0.80,
    this.instructionalComprehension = 0.59,
    // §5 Reading score and CRLA profiles (each cut-off is a lower bound)
    this.startScoreDefault = 10,
    this.highEmergingMin = 20,
    this.developingMin = 40,
    this.transitioningMin = 60,
    this.gradeLevelMin = 80,
    this.targetAccuracy = 0.935,
    this.accuracyWeight = 250,
    this.targetComprehension = 0.66,
    this.comprehensionWeight = 15,
    this.wcpmAtZero = 20,
    this.wcpmPerPoint = 0.9,
    this.fluencyWeight = 8,
    this.fluencyRatioMin = 0.5,
    this.fluencyRatioMax = 1.5,
    this.targetMastery = 0.6,
    this.masteryWeight = 10,
    this.evidenceMaxGap = 30,
    this.scoreLearningRate = 0.35,
    this.maxScoreStep = 12,
    // §6 Reading check
    this.readingCheckTargets = const [15, 40, 65],
    // §9 Accuracy prediction
    this.priorSpread = 10,
    this.priorMin = 0.02,
    this.priorMax = 0.98,
    this.predictionBiasStart = 1.6,
    this.textGapWeight = 0.5,
    this.textGapMaxSteps = 4,
    this.biasLearningRate = 0.3,
    this.biasMin = -2,
    this.biasMax = 5,
    this.accuracyClampMin = 0.01,
    this.accuracyClampMax = 0.995,
    this.instructionalPicks = 3,
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

  /// Filipino spelling variants count as the same word (lumpiya = lumpia,
  /// letse = leche, plastic = plastik; AGENT_SPEC §1).
  final bool filSpellingVariants;

  /// The Filipino Vosk model (about 860 MB in memory) is only loaded with
  /// at least this much free memory; otherwise Filipino uses tap-to-read.
  final int filMinFreeMemoryMb;

  /// Loading it longer than this counts as "too heavy for this phone".
  final int filMaxLoadSeconds;

  /// Median ms from a word being said to the model reporting it (over 10
  /// words); slower counts as "too slow on this phone".
  final int filMaxRecognizerMs;

  final double hintWaitSec;
  final double dyslexiaHintWaitSec;

  /// After this long with no speech heard, the hint timer pauses and Buddy
  /// says he can't hear (never shorter than the hint wait, so a child who
  /// stops after reading a word still gets the first hint).
  final double noSpeechSec;
  final double hintSuccessWindowSec;
  final int hintLearningMinUses;
  final double hintLevel2SuccessMin;
  final double hintLevel1SuccessMax;

  final double independentAccuracy;
  final double instructionalAccuracy;
  final double independentComprehension;
  final double instructionalComprehension;


  /// §5 Reading score (0–100). Used when the reading check was closed
  /// before any passage was finished.
  final double startScoreDefault;

  /// CRLA profile cut-offs on the reading score (lower bounds): below
  /// [highEmergingMin] is Low Emerging (🌱 Seed), then High Emerging
  /// (🌿 Sprout), Developing (🍃 Leaf), Transitioning (🌳 Tree) and from
  /// [gradeLevelMin] Reading at Grade Level (⭐ Super Reader).
  final double highEmergingMin;
  final double developingMin;
  final double transitioningMin;
  final double gradeLevelMin;

  /// Evidence from one reading = book difficulty + these parts (§5).
  /// accuracyPart = accuracyWeight × (accuracy − targetAccuracy).
  final double targetAccuracy;
  final double accuracyWeight;

  /// comprehensionPart = comprehensionWeight × (comprehension − target).
  final double targetComprehension;
  final double comprehensionWeight;

  /// expectedWcpm(D) = wcpmAtZero + wcpmPerPoint × D; fluencyPart =
  /// fluencyWeight × (clamp(WCPM / expected, min, max) − 1).
  final double wcpmAtZero;
  final double wcpmPerPoint;
  final double fluencyWeight;
  final double fluencyRatioMin;
  final double fluencyRatioMax;

  /// masteryPart = masteryWeight × (bookMastery − targetMastery).
  final double targetMastery;
  final double masteryWeight;

  /// Evidence stays within the book difficulty ± this.
  final double evidenceMaxGap;

  /// The score moves this share of the way to the evidence, at most
  /// [maxScoreStep] points per reading.
  final double scoreLearningRate;
  final double maxScoreStep;

  /// §6 Book difficulties the reading-check passages aim for.
  final List<double> readingCheckTargets;

  /// §9 Prior mastery of a sound not read yet: σ((score − 100 × d) /
  /// priorSpread), kept within [priorMin, priorMax].
  final double priorSpread;
  final double priorMin;
  final double priorMax;

  /// The learner's prediction correction starts here (logit units).
  final double predictionBiasStart;

  /// textGapWeight × clamp((score − D) / 10, ±textGapMaxSteps) is added to
  /// each word's logit: books harder than the reader's score come down.
  final double textGapWeight;
  final double textGapMaxSteps;

  /// After each story: bias += biasLearningRate × (logit(actual) −
  /// logit(predicted)), kept within [biasMin, biasMax]. Accuracies are
  /// clamped to [accuracyClampMin, accuracyClampMax] first.
  final double biasLearningRate;
  final double biasMin;
  final double biasMax;
  final double accuracyClampMin;
  final double accuracyClampMax;

  /// Instructional ("just right") books on the shelf; one more slot is the
  /// easy re-read.
  final int instructionalPicks;

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
