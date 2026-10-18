# Project Brief – ReadAloud Buddy

**Title:** ReadAloud Buddy: An Intelligent Reading Companion for Early-Grade Learners
**Course:** CS 403 – Intelligent Agents (TIP Quezon City). SDG 4 (Quality Education), also SDG 10.

## Problem
- World Bank: ~91% of Filipino 10-year-olds cannot read and understand a simple text ("learning poverty"); already 69.5% in 2019, before COVID.
- Kids improve reading fluency by reading aloud to someone who listens and corrects. Teachers with 40+ pupils can't do this daily, many parents can't help, practice materials don't adapt, and struggling readers are found late.

## Users
| User | Ages / who | Gets |
|---|---|---|
| Child (primary) | 5–9, Kinder–Grade 3, esp. struggling readers | Stories at the right level, word-by-word help, stars + a growing reading pet |
| Parent/guardian | sets up the app, often a shared phone | Weekly summary + one tip; prints tricky words |
| Teacher (later phase) | K–3 teachers | Class dashboard, flagged learners, most-missed sounds |

## Core loop (what the app does)
1. Parent sets up a reader (nickname, grade, language EN/FIL/both, optional class code, consent).
2. Reading check: child reads up to 3 short passages → agent sets a starting reading score (0–100).
3. Story shelf: agent predicts the child's word accuracy for every book and picks up to 3 "just right" (Instructional) books plus one easy re-read, favoring their weak sounds.
4. Read-along: speech recognition tracks each word; words turn green (read), amber (took a while), current word yellow.
5. Stuck on a word → hint ladder: first sound → word parts → whole word (spoken + shown).
6. 3 picture-based comprehension questions, read aloud.
7. Results: stars, % words right, words per minute, questions right, "Buddy's plan" (how it went; a new reading rank is celebrated), new tricky words.
8. Tricky-word game: "build the word" with letter tiles from the child's weak words.
9. Settings: dyslexia-friendly mode (Lexend, wider spacing, cream page), text size, high contrast, read instructions aloud, hint wait time, multiple readers per phone.
10. Parent weekly summary.

## MVP scope (build this first)
In: screens 1–10 from `SCREENS.md`, EN + FIL, the 20 stories in `assets/data/stories.json`, full agent from `AGENT_SPEC.md`, local SQLite, offline-capable, shared-device profiles.
Later: parent summary (screen 11), teacher web dashboard (screens 12–13) + Firebase sync, Vosk offline speech, more stories (Let's Read library), mother-tongue languages, kinder letter-sound mode.

## Non-negotiables
- Works offline on a cheap Android phone.
- No audio stored or uploaded. No ads. No purchases.
- Rewards are for practicing, never for speed.
- When speech recognition is unsure about a word, mark it "unsure" and never count it against the child.
