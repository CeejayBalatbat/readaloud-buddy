# Local Data Model (SQLite)

Stories and sound patterns are read-only content loaded from `assets/data/*.json` (not stored in tables, or cached on first launch).

| Table | Columns |
|---|---|
| `learners` | id (uuid), nickname, grade (0=Kinder..3), languages ("EN","FIL","EN,FIL"), class_code?, reading_score (0–100, AGENT_SPEC §5), prediction_bias? (null = config default 1.6, §9), dyslexia_mode (bool), text_scale, high_contrast, read_aloud, hint_wait_sec, start_hint_level (1–2), stars, created_at |
| `sessions` | id, learner_id, story_id, type ("placement" \| "story"), started_at, reading_seconds, words_total, words_correct, questions_total, questions_correct, hesitations, miscues, skips, unsure_words, hints_given, accuracy, wcpm, comprehension, philiri_level, book_difficulty (0–100), score_before, score_after (for a reading-check passage both are that passage's evidence, §6), predicted_accuracy? (§9; null for reading-check passages) |
| `word_events` | id, session_id, position, word, primary_pattern, result, response_ms, hint_level |
| `mastery` | learner_id, pattern_code, mastery (0–1), observations, updated_at (PK learner_id+pattern_code) |
| `tricky_words` | learner_id, word, pattern_code, added_at, clean_reads (0–2) |
| `hint_stats` | learner_id, hint_level, uses, successes |
| `flags` | learner_id, reason, created_at, seen (bool) |
| `settings` | key, value (parent PIN, consent date, etc.) |

No audio, no full names, no photos, no location.

**Schema version 2** (reading score redesign): `current_level` → `reading_score` (old level 1–4 → 10/30/50/70), sessions' `agent_decision`/`level_before`/`level_after` → `book_difficulty`/`score_before`/`score_after` (same mapping) + `predicted_accuracy` (null for old rows). The migration is in `app_database.dart`.
Matches the columns in `docs/dataset/*.csv` closely, so those CSVs can seed a demo database.
