# Local Data Model (SQLite)

Stories and sound patterns are read-only content loaded from `assets/data/*.json` (not stored in tables, or cached on first launch).

| Table | Columns |
|---|---|
| `learners` | id (uuid), nickname, grade (0=Kinder..3), languages ("EN","FIL","EN,FIL"), class_code?, current_level (1–4), dyslexia_mode (bool), text_scale, high_contrast, read_aloud, hint_wait_sec, start_hint_level (1–2), stars, created_at |
| `sessions` | id, learner_id, story_id, type ("placement" \| "story"), started_at, reading_seconds, words_total, words_correct, questions_total, questions_correct, hesitations, miscues, skips, unsure_words, hints_given, accuracy, wcpm, comprehension, philiri_level, agent_decision ("up" \| "stay" \| "down"), level_before, level_after |
| `word_events` | id, session_id, position, word, primary_pattern, result, response_ms, hint_level |
| `mastery` | learner_id, pattern_code, mastery (0–1), observations, updated_at (PK learner_id+pattern_code) |
| `tricky_words` | learner_id, word, pattern_code, added_at, clean_reads (0–2) |
| `hint_stats` | learner_id, hint_level, uses, successes |
| `flags` | learner_id, reason, created_at, seen (bool) |
| `settings` | key, value (parent PIN, consent date, etc.) |

No audio, no full names, no photos, no location.
Matches the columns in `docs/dataset/*.csv` closely, so those CSVs can seed a demo database.
