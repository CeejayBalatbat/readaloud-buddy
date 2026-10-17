"""Checks a release APK for Android's 16 KB page-size rules.

    flutter build apk --release --split-per-abi
    python tools/check_apk.py build/app/outputs/flutter-apk/app-arm64-v8a-release.apk

For every native library (lib/<abi>/*.so) it checks that the ELF LOAD
segments are aligned to at least 16 KB (0x4000) and that the APK itself is
16 KB zip-aligned (zipalign -P 16). It also fails if the Vulkan validation
layer (a debug-only library) got into the APK. Needs the Android SDK with
an NDK (for llvm-readelf) and build-tools (for zipalign).
"""

import os
import re
import subprocess
import sys
import tempfile
import zipfile
from pathlib import Path

SDK = Path(os.environ.get("ANDROID_HOME") or os.environ.get("ANDROID_SDK_ROOT")
           or Path(os.environ.get("LOCALAPPDATA", "")) / "Android" / "Sdk")


def newest(pattern):
    found = sorted(SDK.glob(pattern))
    if not found:
        sys.exit(f"Not found under {SDK}: {pattern}")
    return found[-1]


def main():
    if len(sys.argv) != 2:
        sys.exit(__doc__)
    apk = Path(sys.argv[1])
    exe = ".exe" if os.name == "nt" else ""
    readelf = newest(f"ndk/*/toolchains/llvm/prebuilt/*/bin/llvm-readelf{exe}")
    zipalign = newest(f"build-tools/*/zipalign{exe}")
    problems = []

    with zipfile.ZipFile(apk) as z, tempfile.TemporaryDirectory() as tmp:
        libs = [i for i in z.infolist() if i.filename.startswith("lib/") and i.filename.endswith(".so")]
        for info in libs:
            name = info.filename
            if "VkLayer_khronos_validation" in name:
                problems.append(f"{name}: Vulkan validation layer (debug only) is in the APK")
            path = z.extract(info, tmp)
            out = subprocess.run([str(readelf), "-lW", path], capture_output=True, text=True).stdout
            aligns = {int(line.split()[-1], 16) for line in out.splitlines()
                      if line.strip().startswith("LOAD")}
            worst = min(aligns) if aligns else 0
            status = "OK" if worst >= 0x4000 else "NOT 16 KB aligned"
            print(f"{name}: LOAD align {', '.join(hex(a) for a in sorted(aligns))} {status}")
            if worst < 0x4000:
                problems.append(f"{name}: LOAD segments aligned to {hex(worst)}, need 0x4000")

    zip_check = subprocess.run([str(zipalign), "-c", "-P", "16", "4", str(apk)],
                               capture_output=True, text=True)
    print("zipalign -P 16:", "OK" if zip_check.returncode == 0 else "FAILED")
    if zip_check.returncode != 0:
        problems.append("APK is not 16 KB zip-aligned: " + zip_check.stdout.strip()[-200:])

    if problems:
        print("\nProblems:")
        for p in problems:
            print("  " + p)
        sys.exit(1)
    print("\nAll native libraries are 16 KB-page compatible; no Vulkan validation layer.")


if __name__ == "__main__":
    main()
