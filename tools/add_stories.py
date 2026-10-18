"""Adds new stories to the library from a plain text file.

    python -m pip install cmudict                        # once
    python tools/add_stories.py my_stories.txt           # check, show what it would add
    python tools/add_stories.py my_stories.txt --write   # add them

The format is in docs/ADDING_STORIES.md. For each new story this gives it
the next id (S21, S22, ...), splits the text into words and tags each one
(sound patterns, syllables, difficulty; words already in the library keep
their tags), writes the question ids, regenerates phonics.json (English
hints), computes every book's difficulty (AGENT_SPEC §11) and validates the
whole library. Nothing is written unless everything is valid.
"""

import argparse
import re
import subprocess
import sys

import cmudict

import gen_phonics
import story_difficulty
import storylib as L

FIELD = re.compile(r"^(title|language|text|question|type)\s*:\s*(.*)$", re.IGNORECASE)


class FormatError(Exception):
    pass


def parse(text):
    """Story drafts from the text format: [{title, language, text,
    questions: [{question, type, choices: [(text, emoji, correct)]}]}]."""
    drafts, errors = [], []
    cur = q = None
    mode = None
    for n, raw in enumerate(text.splitlines(), 1):
        line = raw.strip()
        if not line or line.startswith("#"):
            continue
        if re.fullmatch(r"===+\s*story\s*=*", line, re.IGNORECASE):
            cur = {"title": "", "language": "", "text": [], "questions": [], "line": n}
            drafts.append(cur)
            q, mode = None, "head"
            continue
        if cur is None:
            errors.append(f"line {n}: start each story with a line '=== story'")
            continue
        m = FIELD.match(line)
        if m and (mode != "text" or m.group(1).lower() == "question"):
            key, val = m.group(1).lower(), m.group(2).strip()
            if key in ("title", "language"):
                if mode not in ("head",):
                    errors.append(f"line {n}: put '{key}:' before 'text:'")
                cur[key] = val if key == "title" else val.upper()
            elif key == "text":
                mode = "text"
                if val:
                    cur["text"].append(val)
            elif key == "question":
                q = {"question": val, "type": "literal", "choices": [], "line": n}
                cur["questions"].append(q)
                mode = "question"
            elif key == "type":
                if q is None:
                    errors.append(f"line {n}: 'type:' belongs under a 'question:'")
                else:
                    q["type"] = val.lower()
            continue
        if mode == "text":
            cur["text"].append(line)
        elif mode == "question" and line[0] in "*-":
            answer, _, emoji = line[1:].strip().partition("|")
            q["choices"].append((answer.strip(), emoji.strip(), line[0] == "*"))
        else:
            errors.append(f"line {n}: don't understand {line!r}")
    for d in drafts:
        at = f"story at line {d['line']} ({d['title'] or 'no title'})"
        d["text"] = " ".join(d["text"]).strip()
        if not d["title"]:
            errors.append(f"{at}: missing 'title:'")
        if d["language"] not in L.LANGUAGES:
            errors.append(f"{at}: 'language:' must be EN or FIL")
        if not d["text"]:
            errors.append(f"{at}: missing 'text:'")
        if len(d["questions"]) != L.QUESTIONS_PER_STORY:
            errors.append(f"{at}: has {len(d['questions'])} questions, needs exactly 3")
        for i, qq in enumerate(d["questions"], 1):
            qa = f"{at}, question {i}"
            if not qq["question"]:
                errors.append(f"{qa}: the question is empty")
            if qq["type"] not in ("literal", "inferential"):
                errors.append(f"{qa}: type must be literal or inferential")
            if len(qq["choices"]) != L.CHOICES_PER_QUESTION:
                errors.append(f"{qa}: has {len(qq['choices'])} answers, needs exactly 3")
            if sum(1 for c in qq["choices"] if c[2]) != 1:
                errors.append(f"{qa}: mark exactly one answer with '*'")
            for text_, emoji, _ in qq["choices"]:
                if not text_ or not emoji:
                    errors.append(f"{qa}: write each answer as 'text | emoji'")
    if errors:
        raise FormatError("\n".join(errors))
    return drafts


def next_id(stories, k):
    n = max((int(s["id"][1:]) for s in stories if re.fullmatch(r"S\d+", s["id"])), default=0)
    return f"S{n + k:02d}"


def build_story(draft, sid, pattern_info, lex, cmu):
    """The stories.json entry for one draft (difficulty is filled in later),
    and the words that were tagged by rules: [(word, patterns)]."""
    words, new_words = [], []
    for i, tok in enumerate(L.tokens(draft["text"]), 1):
        w = L.word_of(tok)
        if not w:
            raise FormatError(f"{sid} ({draft['title']}): {tok!r} is not a word "
                              "(join punctuation to the word next to it)")
        tags, by_rules = L.tag_word(w, draft["language"], pattern_info, lex, cmu)
        key = (draft["language"], w.lower())
        if by_rules and key not in lex:
            new_words.append((w, tags["patterns"]))
        lex[key] = tags
        words.append({"position": i, "word": w, **tags})
    questions = []
    for i, q in enumerate(draft["questions"], 1):
        right = next(c for c in q["choices"] if c[2])
        questions.append({
            "id": f"{sid}-Q{i}",
            "question": q["question"],
            "answer": right[0],
            "type": q["type"].capitalize(),
            "choices": [{"text": t, "emoji": e, "correct": c} for t, e, c in q["choices"]],
        })
    story = {
        "id": sid,
        "title": draft["title"],
        "language": draft["language"],
        "difficulty": 0,
        "text": draft["text"],
        "words": words,
        "questions": questions,
    }
    return story, new_words


def main():
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("file", help="text file with the new stories (docs/ADDING_STORIES.md)")
    ap.add_argument("--write", action="store_true", help="add them (otherwise only check)")
    ap.add_argument("--data-dir", help="use another assets/data folder (for testing)")
    args = ap.parse_args()
    p = L.paths(args.data_dir)

    try:
        with open(args.file, encoding="utf-8-sig") as f:
            drafts = parse(f.read())
    except FormatError as e:
        sys.exit(f"The story file has problems:\n{e}")
    if not drafts:
        sys.exit("No stories found. Each story starts with a line '=== story'.")

    stories = L.load_json(p["stories"])
    titles = {(s["language"], s["title"].lower()) for s in stories}
    dupes = [d["title"] for d in drafts if (d["language"], d["title"].lower()) in titles]
    if dupes:
        sys.exit(f"Already in the library: {', '.join(dupes)}")

    pattern_info = L.load_patterns(p["patterns"])
    lex = L.lexicon(stories)
    cmu = cmudict.dict()
    new, tagged = [], {}
    try:
        for k, d in enumerate(drafts, 1):
            story, words = build_story(d, next_id(stories, k), pattern_info, lex, cmu)
            new.append(story)
            tagged[story["id"]] = words
    except FormatError as e:
        sys.exit(str(e))

    library = stories + new
    phonics, _ = gen_phonics.build(library, cmu)
    library = story_difficulty.apply(library, phonics)
    errors = L.validate(library, phonics, pattern_info)
    if errors:
        print("Not added; please fix:")
        for e in errors:
            print(f"  {e}")
        sys.exit(1)

    new_ids = {s["id"] for s in new}
    new_keys = {L.phonics_key(w["word"]) for s in new if s["language"] == "EN" for w in s["words"]}
    for s in library:
        if s["id"] not in new_ids:
            continue
        print(f"{s['id']}  {s['title']}  ({s['language']}, {len(s['words'])} words, "
              f"difficulty {s['difficulty']})")
        for w, pats in tagged[s["id"]]:
            print(f"    new word {w}: {', '.join(pats)}")
    review = L.review_words(library, phonics, only=new_keys)
    if review:
        print("\nEnglish words to check (add names to MANUAL in tools/gen_phonics.py):")
        for w, reasons in review:
            print(f"  {w}: {'; '.join(reasons)}")

    if not args.write:
        print("\nEverything is valid. Run again with --write to add these stories.")
        return
    L.write_json(p["stories"], library)
    gen_phonics.write(phonics, p["phonics"])
    print(f"\nAdded {len(new)} stories to {p['stories']} and updated {p['phonics'].name}.")
    model = L.ROOT / "build" / "vosk" / "vosk-model-small-en-us-0.15"
    if args.data_dir is None and model.exists() and new_keys:
        subprocess.run([sys.executable, str(L.ROOT / "tools" / "check_vosk_vocab.py")], check=False)
    elif new_keys:
        print("Then run tools/check_vosk_vocab.py (needs the Vosk model) so words the "
              "offline recognizer doesn't know are never held against the child.")


if __name__ == "__main__":
    main()
