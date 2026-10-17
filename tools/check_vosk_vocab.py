"""Lists English story words the offline Vosk model doesn't know.

    python -m pip install vosk
    python tools/get_vosk_model.py            # once, downloads the model
    python tools/check_vosk_vocab.py

Writes assets/data/vosk_vocab.json: {"model": ..., "missing": [...]}. In
grammar mode Vosk can only hear words it knows; when the child should read
a missing word (often a name like "Pip"), the app counts Vosk's "[unk]" at
that spot as an `unsure` word (never against the child, AGENT_SPEC §1).
Re-run after adding stories.
"""

import json
import re
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
MODEL_NAME = "vosk-model-small-en-us-0.15"
MODEL_DIR = ROOT / "build" / "vosk" / MODEL_NAME
STORIES = ROOT / "assets" / "data" / "stories.json"
OUT = ROOT / "assets" / "data" / "vosk_vocab.json"


def main():
    if not MODEL_DIR.exists():
        sys.exit(f"Model not found at {MODEL_DIR}. Run tools/get_vosk_model.py first.")
    stories = json.loads(STORIES.read_text(encoding="utf-8"))
    words = sorted({
        re.sub(r"[^a-z']", "", w["word"].lower())
        for s in stories if s["language"] == "EN" for w in s["words"]
    } - {""})

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
    text = run.stderr
    missing = sorted(set(re.findall(r"Ignoring word missing in vocabulary: '([^']+)'", text)))

    OUT.write_text(json.dumps({"model": MODEL_NAME, "missing": missing}, indent=1) + "\n",
                   encoding="utf-8")
    print(f"{len(words)} English story words; {len(missing)} not in {MODEL_NAME}:")
    print("  " + ", ".join(missing))


if __name__ == "__main__":
    main()
