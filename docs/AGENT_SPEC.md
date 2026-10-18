# Agent Spec – "Buddy"

Agent type: learning agent with a model-based, goal-based core.
Goal: keep each child reading at their **instructional level** (hard enough to learn, easy enough not to give up), and build mastery of weak sounds.

All numbers below go in `lib/agent/agent_config.dart` (except the book-difficulty formula of §11, which lives in the tool that computes it).

There are **no fixed levels or grade shelves.** Children and books sit on the same 0–100 scale: each child has a **reading score** (§5) and each book a **difficulty** (§11). Buddy recommends books by **predicting** how many words the child will read correctly (§9).

## PEAS
- **Performance:** rising words-correct-per-minute (WCPM), accuracy, comprehension, reading score, how close Buddy's accuracy predictions come to the real accuracy, minutes practiced, sessions finished.
- **Environment:** child reading aloud on a phone, story library, background noise. Partly observable (ASR can mishear).
- **Actuators:** word highlighting, spoken/visual hints, next-story choice, game word lists, rewards, reading-score updates, teacher flags.
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

The Phil-IRI result is still worked out and saved for **every** reading (stars, teacher flag, Buddy's brain), but it no longer moves the child between levels; the reading score (§5) does that job.

## 5. Reading score and reading profile (after each story)
Every learner has a **reading score** from 0 to 100, on the same scale as book difficulty (§11): a child with score 45 reads books of difficulty about 45 at the instructional level.

**After each story** (book difficulty `D`, scores from §3):
```
accuracyPart      = 250 × (accuracy − 0.935)                     // 97% → +8.75, 90% → −8.75
comprehensionPart = 15 × (comprehension − 0.66)                  // 3/3 → +5, 2/3 → 0, 1/3 → −5
fluencyPart       = 8 × (clamp(WCPM / expectedWcpm(D), 0.5, 1.5) − 1)   // −4 … +4
                    expectedWcpm(D) = 20 + 0.9 × D               // 20 words/min at 0 … 110 at 100
masteryPart       = 10 × (bookMastery − 0.6)                      // −6 … +4
                    bookMastery = average over the book's words of the word's weakest
                    pattern mastery (§7), after this reading's update
evidence  = D + accuracyPart + comprehensionPart + fluencyPart + masteryPart,
            kept within D ± 30 and within 0–100
newScore  = score + clamp(0.35 × (evidence − score), −12, +12)
```
In words: "what this reading says about the child" is the book's difficulty, nudged up or down by how many words were right, how fast, how many questions were right, and how well Buddy thinks the child knows the book's sounds. The score moves 35% of the way toward it, never more than 12 points at once.

**Reading profile** (DepEd CRLA-style) from the score; the cut-offs are lower bounds in the config:
| Score | Profile (teachers and parents see) | Rank (children see) |
|---|---|---|
| 0–19 | Low Emerging | 🌱 Seed |
| 20–39 | High Emerging | 🌿 Sprout |
| 40–59 | Developing | 🍃 Leaf |
| 60–79 | Transitioning | 🌳 Tree |
| 80–100 | Reading at Grade Level | ⭐ Super Reader |

Children never see the number or the CRLA label, only their rank. Parents and teachers see the profile and the score.

**Buddy's plan** on the Results screen (kid words): a new higher rank is celebrated ("You grew into a 🌳 Tree reader!"); a lower rank is never announced (Buddy says it'll pick some easier stories for a while); otherwise Buddy says how the story felt (from Phil-IRI) and, if the score went up, that the child is growing toward the next rank.

## 6. Reading check (sets the starting score)
Child reads up to 3 short passages (the opening sentences, about 25 words) from books in their first reading language, chosen with difficulty closest to the targets **15, 40 and 65** (each book once). Stop at the first Frustration result (word accuracy < 90%, §4; there are no questions). No score is shown to the child.

Each passage gives `evidence = D + accuracyPart + fluencyPart` (§5, no questions or mastery part), kept within D ± 30 and 0–100.
**Starting score:**
- the last passage that was **not** Frustration and the Frustration passage (if any) are averaged;
- if only one of them exists, its evidence is the start score;
- if the check was closed before any passage was finished: `startScoreDefault` = 10.

Sound mastery, tricky words and hint stats learn from the passages as before.

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

**Tricky-word game ("Build the word", screen 9):** 5 words per game. The learner's tricky words first (weakest pattern mastery first, then fewest clean reads), topped up with words from the stories Buddy would recommend (§9: predicted not Frustration; if there are none, the easiest predicted books) in their language(s) that practise their weakest sounds (no sight words, nothing hyphenated, 2–8 letters). Buddy says the word; the child taps or drags letter tiles (the word's letters + 2 look-alike letters) into the slots; a wrong tile goes back and counts as a mistake. A word built with **no** mistakes counts as one clean read for this list; a build with mistakes doesn't count but doesn't reset it. Finishing a game earns 1 ⭐ (for practising). "Why this game?" names the sounds, and says honestly whether the words came from the tricky list.

## 9. Story recommendation by prediction (story shelf)
Candidates: every story in the learner's reading language(s) (a reader set to "Both", `EN,FIL`, sees both).

**Predicted word accuracy** of a book for this learner (score `S`, book difficulty `D`):
```
for each sound pattern p:
  m(p) = BKT mastery (§7)                         if the learner has read p at least once
       = clamp(σ((S − 100 × d_p) / 10), 0.02, 0.98)   otherwise ("prior from the score")
         d_p = the pattern's difficulty (0–1) in assets/data/sound_patterns.json
for each word w of the book:
  m_w   = the lowest m(p) of the word's patterns   (the weakest sound decides)
  raw_w = m_w × (1 − slip) + (1 − m_w) × guess    (BKT chance of reading it right, §7 params)
  p_w   = σ( logit(raw_w) + bias + 0.35 × clamp((S − D) / 10, −3, 3) )
predicted accuracy = average of p_w over the book's words
```
σ is the logistic function, logit its inverse. The last term is a small correction for books that are longer or have longer sentences than the child is used to (sounds alone don't make a book hard). `bias` is the learner's **prediction correction**, starting at 1.6.

**Learning from the error:** before each story's results are saved, Buddy computes the predicted accuracy (with the mastery and score from *before* the reading) and saves it with the session. Afterwards:
```
bias = clamp(bias + 0.5 × (logit(actual) − logit(predicted)), −2, 5)   // accuracies clamped to 0.01–0.995
```
So if Buddy keeps guessing too high, its next guesses come down, and vice versa. Buddy's brain shows "predicted 93%, actual 91%".

**Bands** (the Phil-IRI word thresholds of §4): predicted ≥ 97% Independent (easy), 90–96% Instructional (just right), < 90% Frustration (too hard).

**The shelf** (up to `shelfSize` = 4 books):
1. Up to 3 **Instructional** books, ordered by
   `weak-sound coverage (average over words of 1 − mastery of each pattern) − 1.0 if read in the last 3 sessions + random 0–0.15` (re-reading is fine: the penalty only changes the order).
2. **One easy re-read:** a book the child has already read that is now predicted Independent, the one with the best past accuracy ("★ Read again"). If there is none, the slot is filled like step 3.
3. If fewer than 4 books so far: the **Independent** books closest to the Instructional band (lowest predicted accuracy first).
4. **Never a predicted-Frustration book**, unless no book at all is Instructional or Independent (a beginning reader): then the 4 books with the highest predicted accuracy, and Buddy says "Let's read these together. I'll help you!".

Explain the pick in one kid-friendly line ("These stories have more 'sh' words").

## 10. Teacher flag
Flag the learner when 2 of their last 3 sessions are Frustration, or a pattern stays "Needs help" after 3 sessions that practiced it.

## 11. Book difficulty (0–100)
Every story in `assets/data/stories.json` has a `difficulty` (0–100, same scale as the reading score), computed by `tools/story_difficulty.py` (also run by `tools/add_stories.py`). Never edit it by hand. Four parts, each clamped to 0–1:
| Part | Weight | 0 at | 1 at |
|---|---|---|---|
| Length (words) | 0.30 | 15 | 90 |
| Sentence length (words per sentence; a sentence ends with . ! ?) | 0.25 | 3.5 | 11 |
| Syllables per word | 0.20 | EN 1.0 · FIL 1.6 | EN 1.5 · FIL 2.25 |
| Hard words: share of words that are tricky + ½ × share of sight words | 0.25 | EN 0.08 · FIL 0.22 | EN 0.26 · FIL 0.46 |

`difficulty = round(100 × weighted sum)`.
Word types: English uses `phonics.json` (`sight`, `decodable`, `tricky`; a per-occurrence entry wins). Filipino has no phonics.json entries, so its types come from the word's patterns: `FIL-SW`/`FIL-MGA` = sight; only `FIL-CV`, `FIL-NG`, `FIL-DIP` = decodable; anything else (clusters, affixes, long words) = tricky. Filipino words are naturally longer, so syllables and hard words have their own anchors per language.

## Test fixtures
`docs/dataset/Sessions.csv` has 550 simulated sessions with `word_accuracy`, `comprehension`, `philiri_level` and `agent_next_action`.
- **Phil-IRI classification** (`word_level`, `comprehension_level`, `philiri_level`): must match the CSV exactly, every row.
- `agent_next_action` (the old level decisions) is no longer used.

## Content notes
- Each question in `assets/data/stories.json` has a `choices` field: 3 answer options (the correct answer + 2 plausible wrong ones, in the story's language), each with a placeholder emoji picture.
- New stories are added with `tools/add_stories.py` (format: `docs/ADDING_STORIES.md`). It tags every word, regenerates `phonics.json`, computes the difficulty and validates everything; `tools/check_stories.py` re-checks the whole library.

## Speech recognition (environment notes)
- **Vosk offline is the only recognizer** (`vosk-model-small-en-us-0.15`, 39 MB, bundled) for English stories. **Grammar mode:** the recognizer only knows the words the child may read now: the current page plus the next page's first `lookAheadWords` words (so a skip across a page turn still matches), or the review words during a page review, plus `[unk]`. The grammar is swapped while the recognizer is briefly paused (~100 ms) at a page turn. It listens **continuously** (no stop/restart gaps). `[unk]` = the child spoke but said none of the page's words: it counts as speech for the hint timer (§2) but is **not** scored as a misread (coughs and "um"s never count against the child); a real misread therefore shows up as being stuck → hints → `correctAfterHint` or `skipped` (both miscues, so Phil-IRI accuracy is unchanged in kind). Story words the model doesn't know (`assets/data/vosk_vocab.json`: jen, marco, turon) are left out of the grammar; `[unk]` where one of them is expected is recorded as `unsure` (§1, excluded from totals).
- **Filipino stories use tap-to-read for now** (there is no small Filipino Vosk model). The reading screen shows a small note: "Filipino listening is coming soon. Tap each word as you read it."
- **Crash protection:** any error Vosk reports switches the story to tap-to-read on the spot, with a small note, and Vosk stays off on this phone. A native crash inside Vosk can't be caught; the app marks when Vosk is running, and if the app died while it was, the next start turns Vosk off (Android 11+ says why the app ended; on older phones any such exit counts). While Vosk is off, stories use tap-to-read; Settings shows why, with "Try offline again".
- **Tap-to-read is a hidden developer/demo option,** not a normal choice: long-press the "How Buddy listens" card in Settings to show it. When it is on, every story uses tap-to-read and the card says so.
- Recognizers write hyphenated words as two words ("araw araw"); when the expected word has a hyphen, its two halves are joined back into one heard word.
