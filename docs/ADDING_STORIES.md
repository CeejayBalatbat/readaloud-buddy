# Adding stories

New stories go into a plain text file. One file can hold many stories.
Then run:

```
python -m pip install cmudict          # once (English pronunciations)
python tools/add_stories.py my_stories.txt          # shows what it would add
python tools/add_stories.py my_stories.txt --write  # adds them
```

`add_stories.py` gives each story the next free id (S21, S22, …), splits
the text into words, tags every word with its sound patterns, syllables
and difficulty, writes question ids, regenerates `assets/data/phonics.json`
(English hints), computes every book's difficulty (AGENT_SPEC §11) and
then validates the whole library. Nothing is written if a story has an
error. Afterwards it lists English words that need a human check (names,
words not in the pronouncing dictionary) and, if the Vosk model is
downloaded, words the offline recognizer doesn't know.

`python tools/check_stories.py` validates the library at any time.
`flutter test` checks the basics too (`test/data/story_test.dart`).
`python tools/story_difficulty.py --check` shows every book's difficulty
and its parts.

## Format

```
=== story
title: Lia and the Kite
language: EN
text:
Lia has a red kite. The wind is strong.
Up, up, up goes the kite! Lia holds the string tight.

question: Who has a red kite?
type: literal
* Lia | 👧
- Ben | 👦
- Mia | 👩

question: What made the kite go up?
type: inferential
* The strong wind | 🌬️
- The rain | 🌧️
- A bird | 🐦

question: What does Lia hold?
* The string | 🧵
- A ball | ⚽
- A book | 📖
```

Rules:
- Each story starts with a line `=== story`.
- `language:` is `EN` or `FIL`.
- `text:` is followed by the story; it can span several lines (they are
  joined with spaces). Use normal punctuation: a sentence ends with
  `.`, `!` or `?`. Hyphenated words (`araw-araw`) stay one word.
- **Exactly 3 questions.** Each starts with `question:`; `type:` is
  `literal` (the default) or `inferential`.
- **Exactly 3 answers per question**, one per line: `*` marks the one
  correct answer, `-` the two wrong ones. After `|` comes the picture
  (one emoji). Answers are in the story's language.
- Lines starting with `#` are comments.

## Tips for a good story
- About 20 words for the easiest books, up to about 90 for the hardest.
  Difficulty is worked out from the length, sentence length, syllables
  and how many sight / decodable / tricky words it has, so you don't set
  it yourself. The tool prints each new book's difficulty.
- Names the pronouncing dictionary doesn't know (e.g. "Thea") are listed
  for review; add them to `MANUAL` in `tools/gen_phonics.py` and run the
  tool again.
- Word tags are reused from the existing stories when a word is already
  there, so the same word is always tagged the same way. New words are
  tagged by rules (e.g. `sh` → EN-SH, 3+ syllables → EN-ML, `nag-`/`mag-`
  → FIL-AFX); check the printed tags of new words.

## Sending new stories
Put them in a file in the format above (several stories per file is fine)
and run `tools/add_stories.py`. Title, language, text and the 3 questions with
3 picture answers each are all that is needed.
