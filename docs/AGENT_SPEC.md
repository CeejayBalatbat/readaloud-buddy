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
| `skipped` | child moved on; later word matched first, or child tapped "Next word →" after the level 3 hint | no |
| `unsure` | ASR confidence < `asrMinConfidence` (0.5) or audio unclear | **excluded** from totals |

**Confidence:** use the recognizer's confidence when it gives one. When it gives none (common on Android partial results), do **not** mark the word `unsure`. Controlled by the config flag `treatMissingConfidenceAsUnsure` (default `false`).

**Word matching:** lowercase, strip punctuation, then compare. Edit-distance (Levenshtein) tolerance is **per language** in the config:
| Language | Tolerance |
|---|---|
| EN | distance ≤ 1 for words with ≥ 5 letters; exact match otherwise |
| FIL | exact match only (distance 0) – one-letter changes are often different words (*bata*/*bato*) |

Align recognized words to expected words left-to-right, allowing a look-ahead of 2 words to detect skips.

## 2. Hint ladder

**Feedback mode (parent setting "Reading feedback"):**
- **Review after each page** (default, "read first, review after"): while the child reads a page, no word colors (green/amber/red) and **no automatic hints** – only a soft marker on the current word. The **Help** button still works (the ladder below, on request). When a page is done and it has `misread` or `skipped` words, Buddy shows a **page review** (screen 5b): each missed word can be heard (tap 🔊, Buddy says it) and said again (the microphone listens for it). The reading clock stops during the review, so WCPM only counts reading time. Practice is **not scored**: word results, accuracy, WCPM and the Phil-IRI level stay exactly as in §1/§3/§4. A page with no missed words goes straight on; after the last page the review comes before the questions. The Hints setting below does not apply in this mode.
- **Live colors and hints**: every word gets its color as soon as it is read, and the timed hint ladder below runs (with the Hints setting).

The rest of this section describes the hint ladder; in review mode only its Help-button part applies.

When the child is stuck on the current word for `hintWaitSec` of **counted** time (default 5 s; 8 s when dyslexia mode is on or set by parent; see "When the hint timer counts"):

**Never say letter names or isolated sounds in hints.** Text-to-speech cannot say a pure sound ("s" comes out as "suh"), so English hints use **keyword pictures** and whole chunks instead, driven by `assets/data/phonics.json`.

**English** – each word in `phonics.json` has a type:
- **Sight** (heart words: the, was, said, one, of, to, you, they, come, some, are, have, do, what, where, there, …): **one hint only**, the whole word – "This one we just know: **the** ❤️" (counts as level 3; then Buddy waits / "Next word →").
- **Decodable** or **tricky** (only part follows the rules):
  1. Level 1 – "It starts like **hat** 🎩": show the **onset** letters highlighted in the word, the keyword and its emoji; say "It starts like… hat". Words starting with a vowel use a vowel keyword (and → apple 🍎).
  2. Level 2 – show the split **onset · rime** ("h · ad", "sh · ip", "str · ong"); say the keyword, the rime chunk, then the word: "hat… ad… had".
  3. Level 3 – say the **whole word**, then **wait** for the child.

**Keywords:** one keyword per first sound, the same for every word (h → hat 🎩, s → sun ☀️, sh → shoe 👟, th /θ/ → thumb 👍, th /ð/ → this 👉, ch → chair 🪑, str → string 🧵, …). The keyword's first sound must match the word's (checked against CMUdict by the generator). If the keyword is the word itself, a second keyword is used (fish → fox 🦊).

**phonics.json** is made by `tools/gen_phonics.py` from the CMU Pronouncing Dictionary for every English story word: type, graphemes (letters grouped by sound, silent letters marked: k·i·t·e(silent)), phonemes (HH AE D), onset/rime, `rime_say` (the rime spelled so TTS reads it right: thread → "ed"), keyword + emoji, and `needs_review` for anything uncertain. Re-run it when stories are added; a word missing from the file gets hints that show the parts but only ever say whole chunks.

**Sound clips (later):** if `assets/sounds/<PHONEME>.mp3` exists for every sound of the onset (e.g. HH.mp3), level 1 plays it instead of saying the keyword. No clips are bundled yet.

**Filipino** stays syllable-based: level 1 = the opening syllable (Abakada style: **ba**·ta, **ma**y, **nga**yon), level 2 = the syllables, then the word ("ba… ta… bata"; a one-syllable word: "ma… may"), level 3 = the word.

Escalate one level each further `hintWaitSec` of counted time (sight words have just the one whole-word step). Record `hintLevel` (0–3) per word.

**When the hint timer counts:** silence from the microphone is not the same as being stuck, so time only counts toward a hint when:
- the child is **speaking but not matching** the current word (the recognizer hears speech, even if it is not a whole word yet), or
- the child **paused mid-reading** after reading at least one word: silence counts until no speech has been heard for `noSpeechSec` (default 8 s; never shorter than `hintWaitSec`, so a child who stops right after reading a word always gets the first hint).

It never counts:
- on the **first word of a page**, because the child may not have started reading yet;
- while the recognizer has **heard no speech** for `noSpeechSec`. Then the timer **pauses** (it is not reset) and Buddy shows a friendly "I can't hear you. Try reading a bit louder!" message. The message goes away and the timer carries on as soon as speech is heard again. This applies only with a real microphone; tap-to-read has no voice to listen for.
- when the parent set **Hints = Only when I tap Help**.

**Never auto-skip.** After level 3 Buddy waits for the child and shows a **"Next word →"** button. Only tapping it marks the word `skipped`.

**After level 3:** if the child then reads the word → `correctAfterHint`; if they tap "Next word →" → `skipped`. Both count as miscues.

**Help button:** works any time (first word of a page, while the mic hears nothing, in Help-only mode). It gives the next hint step right away, or says the whole word again after level 3. The next automatic step is due one `hintWaitSec` of counted time after it.

**Parent setting:** Hints = **Automatic** (default; the rules above) / **Only when I tap Help** (no timed hints; Help still works).

**Recognizer restarts:** the recognizer often stops on silence; whenever it stops while a story is open, listening restarts automatically. A recognizer restart does not reset the hint timer.

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

**Tricky-word game ("Build the word", screen 9):** 5 words per game. The learner's tricky words first (weakest pattern mastery first, then fewest clean reads), topped up with words from stories at their level and language(s) that practise their weakest sounds (no sight words, nothing hyphenated, 2–8 letters). Buddy says the word; the child taps or drags letter tiles (the word's letters + 2 look-alike letters) into the slots; a wrong tile goes back and counts as a mistake. A word built with **no** mistakes counts as one clean read for this list; a build with mistakes doesn't count but doesn't reset it. Finishing a game earns 1 ⭐ (for practising). "Why this game?" names the sounds, and says honestly whether the words came from the tricky list.

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
- **Filipino (fil-PH):** the first time a Filipino story opens in microphone mode, the app checks whether the phone's recognizer lists `fil-PH` (or the older `tl-PH`). If it does, Filipino stories use the microphone; if not, they fall back to tap-to-read and Buddy says so on the reading screen. (If the phone lists no languages at all, the microphone is tried, and a recognizer error shows the usual "mic not ready" message.)
- Recognizers write hyphenated words as two words ("araw araw"); when the expected word has a hyphen, its two halves are joined back into one heard word.
