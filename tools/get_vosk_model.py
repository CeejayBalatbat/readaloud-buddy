"""Downloads the offline English speech model (Vosk) used by the app.

    python tools/get_vosk_model.py

The model is 39 MB, so it is not kept in git. This puts:
  assets/models/vosk-model-small-en-us-0.15.zip   (bundled into the app)
  build/vosk/vosk-model-small-en-us-0.15/         (unzipped, for tools/)
The download is checked against the MD5 that alphacephei.com publishes.
License: Apache 2.0 (https://alphacephei.com/vosk/models).
"""

import hashlib
import json
import sys
import urllib.request
import zipfile
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
NAME = "vosk-model-small-en-us-0.15"
MD5 = "09ab50ccd62b674cbaa231b825f9c1cb"  # from model-list.json
URL = f"https://alphacephei.com/vosk/models/{NAME}.zip"
ZIP = ROOT / "assets" / "models" / f"{NAME}.zip"
UNZIPPED = ROOT / "build" / "vosk"


def md5(path):
    h = hashlib.md5()
    with open(path, "rb") as f:
        for chunk in iter(lambda: f.read(1 << 20), b""):
            h.update(chunk)
    return h.hexdigest()


def main():
    ZIP.parent.mkdir(parents=True, exist_ok=True)
    if not ZIP.exists() or md5(ZIP) != MD5:
        print(f"Downloading {URL} (39 MB)...")
        tmp = ZIP.with_suffix(".part")
        urllib.request.urlretrieve(URL, tmp)
        if md5(tmp) != MD5:
            tmp.unlink()
            sys.exit("Download corrupted (MD5 mismatch); try again.")
        tmp.replace(ZIP)
    print(f"OK: {ZIP.relative_to(ROOT)}")
    if not (UNZIPPED / NAME).exists():
        with zipfile.ZipFile(ZIP) as z:
            z.extractall(UNZIPPED)
    print(f"OK: {(UNZIPPED / NAME).relative_to(ROOT)}")


if __name__ == "__main__":
    main()
