"""Validates the story library (assets/data/stories.json).

    python tools/check_stories.py

Checks every story: id, language, that the tagged words line up with the
text, known sound patterns, 3 questions with 3 picture answers and exactly
one correct, an up-to-date difficulty (0–100) and a phonics.json entry
for every English word. Lists English words that need a human check.
Exits with an error if anything is wrong.
"""

import argparse
import sys

import storylib as L


def main():
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("--data-dir", help="use another assets/data folder (for testing)")
    args = ap.parse_args()
    p = L.paths(args.data_dir)
    stories = L.load_json(p["stories"])
    phonics = L.load_json(p["phonics"])
    errors = L.validate(stories, phonics, L.load_patterns(p["patterns"]))
    review = L.review_words(stories, phonics)
    langs = {lang: sum(1 for s in stories if s["language"] == lang) for lang in L.LANGUAGES}
    print(f"{len(stories)} stories ({', '.join(f'{n} {k}' for k, n in langs.items())}).")
    if review:
        print(f"{len(review)} English words need a human check (tools/gen_phonics.py):")
        for w, reasons in review:
            print(f"  {w}: {'; '.join(reasons)}")
    if errors:
        print(f"\n{len(errors)} problems:")
        for e in errors:
            print(f"  {e}")
        sys.exit(1)
    print("All stories are valid.")


if __name__ == "__main__":
    main()
