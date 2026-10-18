"""Computes every book's difficulty (0–100, AGENT_SPEC §11) and writes it
into assets/data/stories.json as "difficulty".

    python tools/story_difficulty.py           # update stories.json
    python tools/story_difficulty.py --check   # only show the table

Difficulty comes from the length, sentence length, syllables per word and
the share of sight / decodable / tricky words (phonics.json for English,
word patterns for Filipino). Run tools/gen_phonics.py first if English
stories changed (tools/add_stories.py does all of this for you).
"""

import argparse
import sys

import storylib as L


def apply(stories, phonics):
    """Sets "difficulty" on every story (right after "language")."""
    out = []
    for s in stories:
        d = L.book_difficulty(s, phonics)
        new = {}
        for k, v in s.items():
            if k == "difficulty":
                continue
            new[k] = v
            if k == "language":
                new["difficulty"] = d
        out.append(new)
    return out


def table(stories, phonics):
    rows = []
    for s in sorted(stories, key=lambda s: (s["language"], L.book_difficulty(s, phonics))):
        parts, raw = L.difficulty_parts(s, phonics)
        rows.append(
            f"  {s['id']:>4} {s['language']:<3} {L.book_difficulty(s, phonics):>3}  "
            f"{raw['words']:>3} words, {raw['words_per_sentence']:>4}/sentence, "
            f"{raw['syllables_per_word']:.2f} syl/word, "
            f"sight {raw['sight']:.2f} decodable {raw['decodable']:.2f} tricky {raw['tricky']:.2f}"
            f"  {s['title']}")
    return "\n".join(rows)


def main():
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("--check", action="store_true", help="don't write, just show")
    ap.add_argument("--data-dir", help="use another assets/data folder (for testing)")
    args = ap.parse_args()
    p = L.paths(args.data_dir)
    stories = L.load_json(p["stories"])
    phonics = L.load_json(p["phonics"])
    print("Book difficulty (0–100), easiest first per language:")
    print(table(stories, phonics))
    if args.check:
        stale = [s["id"] for s in stories if s.get("difficulty") != L.book_difficulty(s, phonics)]
        if stale:
            sys.exit(f"Out of date: {', '.join(stale)}. Run without --check.")
        return
    L.write_json(p["stories"], apply(stories, phonics))
    print(f"Wrote difficulty for {len(stories)} stories to {p['stories']}")


if __name__ == "__main__":
    main()
