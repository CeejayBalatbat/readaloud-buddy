# Screens (approved design – see docs/mockups/sNN.png)

Style: warm cream background `#FFF8EC`, ink `#26324A`, teal primary `#1F9E8F`, sun yellow `#FFC93C` (big "Read!" button, current word), coral `#FF7A59` (mic), green `#2FA866` (read correctly), amber `#F2A20C` (took a while), violet `#7C6CF2` (anything the agent decides or explains — the "Buddy" card with a sparkle icon). Font Nunito, heavy weights (800–900) for headings. Rounded cards (20px), chunky buttons with a bottom "shadow" edge. Buddy is a teal owl-like mascot holding a coral book (see mockups).
`docs/mockups/screens_source.html` is the HTML/CSS used for the mockups – use it for exact colors/sizes.

| # | Screen | User | Key elements |
|---|---|---|---|
| 1 | Reader setup | Parent | nickname, grade chips, language chips (EN/FIL), class code (optional), consent card (voice processed on phone only), "Start reading check" |
| 2 | Reading check | Child | progress bar, Buddy speech bubble, passage card, "Buddy is checking" agent card, big mic button + waveform |
| 3 | Home | Child | greeting (Filipino time-of-day greeting), stars + streak chips, Buddy pet card with growth bar, today's minutes ring, big yellow "Read!", bottom tabs (Home, Stories, Games, Settings) |
| 4 | Story shelf | Child | level badge, "Buddy picked these" agent card with reason, 2×2 story covers with sound/language chips |
| 5 | Read-along | Child | page x/y, picture, story text, Help / Mic / Pause buttons. **Review mode (default):** only a soft yellow marker on the current word (sun-light background, sun bottom edge), no colors, no legend. **Live mode:** per-word highlight states + legend |
| 5b | Page review | Child | after a page with missed words (review mode): Buddy bubble "Let's practise these words…", one card per misread/skipped word (big word, "🔊 Hear it", "Say it now…" → "✓ You said it!"; the word being listened for has a sun border), "Next page →" / "All done ✓". Not scored |
| 6 | Hint | Child | dimmed story card, "Let's break it up" card (e.g. thr · ough), "Hear the sounds", Buddy encouragement, hint-step pills (1 Sound ✓, 2 Parts, 3 Word) |
| 7 | Story questions | Child | question with speaker button, 3 picture answers, feedback bubble from Buddy |
| 8 | Results | Child | Buddy, "Great reading!", stars, 3 stat tiles (% words right, words/min, questions), "Buddy's plan" agent card, new tricky words, "Word game" / "Next story" |
| 9 | Tricky-word game | Child | picture + "Listen again", letter slots, draggable tiles, "Why this game?" agent card |
| 10 | Reading comfort (the Settings tab) | Parent (locked with an optional 4-digit PIN; "Forgot PIN?" = a grown-up multiplication check) | live preview, dyslexia mode toggle (Lexend, wider spacing, cream page), text size (Small/Medium/Large/Extra large), high contrast, read instructions aloud, wait before a hint (3–12 s or automatic), readers on this phone; then How Buddy listens, Reading feedback, Hints, Grown-up PIN. Comfort settings are saved per reader |
| 11 | Parent weekly summary | Parent (later) | minutes, stories, WCPM gain, level bar, celebrate card, try-at-home tip, print tricky words |
| 12 | Teacher class overview | Teacher web (later) | KPI tiles, learner table sorted by needs attention, most-missed sounds, "Buddy suggests" |
| 13 | Teacher learner detail | Teacher web (later) | WCPM chart vs goal, "What Buddy learned", sound mastery chips, recent sessions |

Story cover art: simple flat illustrations are fine (placeholder shapes/colors per story are OK for MVP).
