# Known issues

Things we found but haven't fixed yet. We fix these in the bug-fixing
round at the end. Add new reports at the bottom of the right section.

## Speech recognition
- **Recognition feels slow** (reported on the phone). On-device recognition
  and partial results are already on. The speed meter (Buddy's brain →
  "Speed", or `[speed]` lines in the `flutter run` console) splits the
  delay into recognizer / settling / screen time. **Needs:** numbers from
  the phone in debug and `--release` builds, then a fix aimed at the slow
  part.
- **Words said while the recognizer restarts are lost.** Android stops
  listening after about 1 s of silence, and we restart it ~250 ms later.
  The speed meter shows this as "Mic off while restarting".
- **Filipino recognition is untested on a real phone.** fil-PH usually has
  no on-device model, so it falls back to online recognition (needs
  internet). The Filipino TTS voice for hints may also be missing on some
  phones (Buddy then stays quiet).
- The speed meter's "recognizer" time counts from when the mic got loud.
  If the child reads several words without a pause, it counts from the
  start of the phrase, so it overestimates later words.

## Hints and phonics
- **TTS rime spellings are unchecked on a real voice** (e.g. "ed" for
  thread, "ont" for want, "oo" for through). Listen for any that sound
  wrong; fixes go in `tools/gen_phonics.py`.
- "honest": the hint highlights the silent **h** as the start, while the
  keyword (octopus 🐙) matches the vowel sound.
- **W keyword changed to window 🪟 for all W words** (went, wet, with…),
  not just "when" and "walked". Revert in `tools/gen_phonics.py` if only
  those two were meant.
- The sound-clip hook (`assets/sounds/<PHONEME>.mp3`) needs an audio
  player package before it does anything.

## Reading check (placement)
- No Help button. With Hints = "Only when I tap Help", a child gets no
  hints at all during the reading check.
- It always uses automatic hints and never shows the page review, whatever
  the Reading feedback setting is.

## Read first, review after
- Words read correctly *after* a hint (via Help) are not in the page
  review; only misread and skipped words are.

## Phase 5 and the weekly summary
- Some keyword/emoji pictures are newer emoji (🪺 nest, 🪟 window, 🪑 chair,
  🪁 kite, 🧃 juice, 🪀). Phones on Android 10 or older may show an empty
  box instead.
- Games don't count toward the streak or today's minutes; only reading does.
- "Build the word" has no picture of the word (the mockup shows one); it
  shows a speaker and Buddy says the word.
- The weekly summary covers the last 7 days (today and the 6 days before),
  not a calendar week.
- Printing tricky words uses Android's print dialog (print or save as PDF);
  untested on a real phone and printer.

