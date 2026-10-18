"""Lists story words the offline Vosk models don't know.

English (needs the model, downloaded once):
    python -m pip install vosk
    python tools/get_vosk_model.py
    python tools/check_vosk_vocab.py

Filipino (the zip or unpacked folder of vosk-model-tl-ph-generic-0.6; it
isn't in the app, so give its path):
    python tools/check_vosk_vocab.py --fil path/to/vosk-model-tl-ph-generic-0.6.zip

Writes assets/data/vosk_vocab.json:
  {"model": ..., "missing": [...], "fil_model": ..., "fil_missing": [...]}
English uses grammar mode, so Vosk can only hear words it knows: "[unk]"
where a missing word is expected counts as `unsure`. The Filipino model
hears free text: a word that isn't on the page where a missing word is
expected counts as `unsure`. Never against the child (AGENT_SPEC §1).
Re-run after adding stories (only the part you have a model for changes).
"""

import argparse
import json
import re
import subprocess
import sys
import zipfile
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
MODEL_NAME = "vosk-model-small-en-us-0.15"
MODEL_DIR = ROOT / "build" / "vosk" / MODEL_NAME
FIL_MODEL_NAME = "vosk-model-tl-ph-generic-0.6"
STORIES = ROOT / "assets" / "data" / "stories.json"
OUT = ROOT / "assets" / "data" / "vosk_vocab.json"


def story_words(stories, language, keep):
    return sorted({
        re.sub(keep, "", w["word"].lower())
        for s in stories if s["language"] == language for w in s["words"]
    } - {""})


def english_missing(stories):
    words = story_words(stories, "EN", r"[^a-z']")
    # Vosk reports unknown grammar words on stderr, so build the
    # recognizer in a child process and read what it prints.
    probe = "\n".join([
        "import sys",
        "from vosk import KaldiRecognizer, Model, SetLogLevel",
        "SetLogLevel(0)",
        "KaldiRecognizer(Model(sys.argv[1]), 16000, sys.argv[2])",
    ])
    run = subprocess.run(
        [sys.executable, "-I", "-c", probe, str(MODEL_DIR), json.dumps(words + ["[unk]"])],
        capture_output=True, text=True, encoding="utf-8", errors="replace", check=True)
    missing = sorted(set(re.findall(r"Ignoring word missing in vocabulary: '([^']+)'", run.stderr)))
    print(f"{len(words)} English story words; {len(missing)} not in {MODEL_NAME}:")
    print("  " + ", ".join(missing))
    return missing


def filipino_vocabulary(path):
    """The words in the model's graph/words.txt (from the zip or folder)."""
    p = Path(path)
    if p.suffix == ".zip":
        with zipfile.ZipFile(p) as z:
            text = z.read(f"{FIL_MODEL_NAME}/graph/words.txt").decode("utf-8")
    else:
        text = (p / "graph" / "words.txt").read_text(encoding="utf-8")
    return {line.split()[0] for line in text.splitlines() if line.strip()}


def filipino_missing(stories, path):
    vocab = filipino_vocabulary(path)
    words = story_words(stories, "FIL", r"[^\w-]")
    # A hyphenated word is heard as its two halves ("araw araw").
    missing = [w for w in words if w not in vocab and not all(h in vocab for h in w.split("-"))]
    print(f"{len(words)} Filipino story words; {len(missing)} not in {FIL_MODEL_NAME}:")
    print("  " + ", ".join(missing))
    return [w.replace("-", "") for w in missing]


def main():
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("--fil", metavar="PATH", help=f"{FIL_MODEL_NAME} zip or folder")
    args = ap.parse_args()
    stories = json.loads(STORIES.read_text(encoding="utf-8"))
    out = json.loads(OUT.read_text(encoding="utf-8")) if OUT.exists() else {}

    if MODEL_DIR.exists():
        out["model"] = MODEL_NAME
        out["missing"] = english_missing(stories)
    elif not args.fil:
        sys.exit(f"Model not found at {MODEL_DIR}. Run tools/get_vosk_model.py first.")
    else:
        print(f"(English model not downloaded: keeping the English list as it is.)")

    if args.fil:
        out["fil_model"] = FIL_MODEL_NAME
        out["fil_missing"] = filipino_missing(stories, args.fil)

    OUT.write_text(json.dumps(out, indent=1) + "\n", encoding="utf-8")
    print(f"Wrote {OUT.relative_to(ROOT)}")


if __name__ == "__main__":
    main()
