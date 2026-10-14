# Agent Spec – "Buddy"

Agent type: learning agent with a model-based, goal-based core.
Goal: keep each child reading at their **instructional level** (hard enough to learn, easy enough not to give up), and build mastery of weak sounds.

All numbers below go in `lib/agent/agent_config.dart`.

## PEAS
- **Performance:** rising words-correct-per-minute (WCPM), accuracy, comprehension, level reached, minutes practiced, sessions finished.
- **Environment:** child reading aloud on a phone, story library, background noise. Partly observable (ASR can mishear).
- **Actuators:** word highlighting, spoken/visual hints, next-story choice, game word lists, rewards, level changes, teacher flags.
- **Sensors:** speech recognition results + timing, help-button taps, question answers.

## 1. Word results (per word, during reading)
Each expected word ends in exactly one result:
| Result | Rule | Counts as correct? |
|---|---|---|
| `correct` | matched within `hesitationSec` (3 s) of the previous word | yes |
| `hesitated` | matched, but took > `hesitationSec` | yes |
| `correctAfterHint` | matched only after a hint was given | **no** (miscue, Phil-IRI style) |
| `misread` | ASR heard a different word in its place | no |
| `skipped` | child moved on; later word matched first | no |
| `unsure` | ASR confidence < `asrMinConfidence` (0.5) or audio unclear | **excluded** from totals |

**Confidence:** use the recognizer's confidence when it gives one. When it gives none (common on Android partial results), do **not** mark the word `unsure`. Controlled by the config flag `treatMissingConfidenceAsUnsure` (default `false`).

**Word matching:** lowercase, strip punctuation, then compare. Edit-distance (Levenshtein) tolerance is **per language** in the config:
| Language | Tolerance |
|---|---|
| EN | distance ≤ 1 for words with ≥ 5 letters; exact match otherwise |
| FIL | exact match only (distance 0) – one-letter changes are often different words (*bata*/*bato*) |

Align recognized words to expected words left-to-right, allowing a look-ahead of 2 words to detect skips.

## 2. Hint ladder
If no progress on the current word for `hintWaitSec` (default 5 s; 8 s when dyslexia mode is on or set by parent):
1. Level 1 – say/show the **first sound** (first letter, or first digraph/blend: th, sh, ch, str, ng…).
2. Level 2 – say/show the **word parts** (syllables, e.g. "thr · ough").
3. Level 3 – say the **whole word**, then move on.

Escalate one level each further `hintWaitSec`. Record `hintLevel` (0–3) per word.

**After level 3:** if the child then reads the word → `correctAfterHint`; if not (Buddy moves on) → `skipped`. Both count as miscues.

**Timer:** the hint timer runs independently of the speech recognizer. The recognizer often stops on silence; whenever it stops while a story is open, listening restarts automatically. A recognizer restart does not reset the hint timer.

**Learning:** track per learner the success rate of each hint level (word read correctly within 5 s after it). If level 2 succeeds ≥ 70% and level 1 < 40% over ≥ 10 uses, start at level 2 for that learner.

## 3. Session scores
```
wordsTotal    = words excluding `unsure`
wordsCorrect  = correct + hesitated
accuracy      = wordsCorrect / wordsTotal
WCPM          = wordsCorrect / (readingSeconds / 60)
comprehension = questionsCorrect / questionsTotal   (3 questions per story)
```

## 4. Phil-IRI level classification
Thresholds have **no gaps** (each is a lower bound; all live in the config):
| | Word accuracy | Comprehension |
|---|---|---|
| Independent | ≥ 97% | ≥ 80% |
| Instructional | ≥ 90% (and < 97%) | ≥ 59% (and < 80%) |
| Frustration | < 90% | < 59% |

Overall: **Frustration** if either is Frustration; **Independent** only if both are Independent; otherwise **Instructional**.

## 5. Level decisions (after each story)
- 2 Independent results in a row at the current level → move **up** one level (max 4).
- `framesToMoveDown` Frustration results in a row → move **down** one level (min 1). Default **1** (as in the proposal). Our dataset showed this can make kids bounce between levels; keep it configurable so we can try 2.
- Otherwise stay.
- **Streaks reset when the level changes** (up or down). Only results since the last level change count.
- **The placement check counts as the first result at the starting level.** E.g. placement ends Independent at level 2 → one more Independent story at level 2 moves the child up.
- The placement check itself never moves a child down.

Show the decision on the Results screen as "Buddy's plan" in kid-friendly words.

## 6. Placement check
Child reads up to 3 short passages (levels 1→3). Stop at the first Frustration result. Start level = highest level that was not Frustration (min 1). No score shown to the child.
Placement tops out at level 3 (even if the level 3 passage is Independent). Children reach level 4 by moving up normally.

## 7. Sound mastery (Bayesian Knowledge Tracing)
Track mastery per learner per sound-pattern code (codes in `assets/data/sound_patterns.json`; each story word lists its patterns).
Params: `p0 = 0.35, learn = 0.12, slip = 0.08, guess = 0.20`.
For every scored word (not `unsure`), for each of its patterns:
```
if correct:  post = m(1-slip) / (m(1-slip) + (1-m)guess)
else:        post = m*slip / (m*slip + (1-m)(1-guess))
m_new = post + (1 - post) * learn
```
"correct" here means the word counts as correct (`correct` or `hesitated`).
Status: Mastered ≥ 0.85, Learning 0.50–0.84, Needs help < 0.50.

## 8. Tricky words
A word becomes "tricky" for a learner if its result was misread, skipped, or correctAfterHint. It leaves the list after it is read cleanly in 2 later sessions or games. A clean read is `correct` **or `hesitated`** (read correctly without help).

## 9. Story selection (story shelf)
Candidates: stories at the learner's level in their reading language(s). A reader set to "Both" (`EN,FIL`) sees stories in both languages. Score each:
```
score = average over story words of (1 - mastery of each word pattern)   // weak-sound coverage
        - 1.0 if read in the last 3 sessions
        + small random 0–0.15 for variety
```
Show **all** candidates up to 4, ordered by score (with today's library that is 2–4 stories). The recently-read penalty only affects **order**, never hides a story – re-reading is good fluency practice. Include one "read again" favorite if available. Explain the pick in one kid-friendly line ("These stories have more 'sh' words").

## 10. Teacher flag
Flag the learner when 2 of their last 3 sessions are Frustration, or a pattern stays "Needs help" after 3 sessions that practiced it.

## Test fixtures
`docs/dataset/Sessions.csv` has 550 simulated sessions with `word_accuracy`, `comprehension`, `philiri_level` and `agent_next_action`.
- **Phil-IRI classification** (`word_level`, `comprehension_level`, `philiri_level`): must match the CSV exactly, every row.
- **Level decisions** (`agent_next_action`): the CSV was generated with looser logic (it counted all past results at a level, even from before a level change). Do **not** force the agent to match every CSV row; write level-decision tests from the rules in §5.

## Content notes
- Each question in `assets/data/stories.json` has a `choices` field: 3 answer options (the correct answer + 2 plausible wrong ones, in the story's language), each with a placeholder emoji picture.

## Speech recognition (environment notes)
- Phase 4 uses Android's recognizer via `speech_to_text`: try on-device recognition first, fall back to online. Phase 4 may therefore need internet (documented in the README). Fully offline speech (Vosk) is a later phase.
