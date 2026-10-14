# Screens (approved design – see docs/mockups/sNN.png)

Style: warm cream background `#FFF8EC`, ink `#26324A`, teal primary `#1F9E8F`, sun yellow `#FFC93C` (big "Read!" button, current word), coral `#FF7A59` (mic), green `#2FA866` (read correctly), amber `#F2A20C` (took a while), violet `#7C6CF2` (anything the agent decides or explains — the "Buddy" card with a sparkle icon). Font Nunito, heavy weights (800–900) for headings. Rounded cards (20px), chunky buttons with a bottom "shadow" edge. Buddy is a teal owl-like mascot holding a coral book (see mockups).
`docs/mockups/screens_source.html` is the HTML/CSS used for the mockups – use it for exact colors/sizes.

| # | Screen | User | Key elements |
|---|---|---|---|
| 1 | Reader setup | Parent | nickname, grade chips, language chips (EN/FIL), class code (optional), consent card (voice processed on phone only), "Start reading check" |
| 2 | Reading check | Child | progress bar, Buddy speech bubble, passage card, "Buddy is checking" agent card, big mic button + waveform |
| 3 | Home | Child | greeting (Filipino time-of-day greeting), stars + streak chips, Buddy pet card with growth bar, today's minutes ring, big yellow "Read!", bottom tabs (Home, Stories, Games, Settings) |
| 4 | Story shelf | Child | level badge, "Buddy picked these" agent card with reason, 2×2 story covers with sound/language chips |
| 5 | Read-along | Child | page x/y, picture, story text with per-word highlight states, legend, Help / Mic / Pause buttons |
| 6 | Hint | Child | dimmed story card, "Let's break it up" card (e.g. thr · ough), "Hear the sounds", Buddy encouragement, hint-step pills (1 Sound ✓, 2 Parts, 3 Word) |
| 7 | Story questions | Child | question with speaker button, 3 picture answers, feedback bubble from Buddy |
| 8 | Results | Child | Buddy, "Great reading!", stars, 3 stat tiles (% words right, words/min, questions), "Buddy's plan" agent card, new tricky words, "Word game" / "Next story" |
| 9 | Tricky-word game | Child | picture + "Listen again", letter slots, draggable tiles, "Why this game?" agent card |
| 10 | Reading comfort | Parent (locked) | live preview, dyslexia mode toggle, text size, high contrast, read aloud, hint wait time, readers on this phone |
| 11 | Parent weekly summary | Parent (later) | minutes, stories, WCPM gain, level bar, celebrate card, try-at-home tip, print tricky words |
| 12 | Teacher class overview | Teacher web (later) | KPI tiles, learner table sorted by needs attention, most-missed sounds, "Buddy suggests" |
| 13 | Teacher learner detail | Teacher web (later) | WCPM chart vs goal, "What Buddy learned", sound mastery chips, recent sessions |

Story cover art: simple flat illustrations are fine (placeholder shapes/colors per story are OK for MVP).
