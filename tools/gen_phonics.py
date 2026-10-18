"""Builds assets/data/phonics.json: how every English story word sounds.

Run again whenever stories are added:

    python -m pip install cmudict
    python tools/gen_phonics.py

For each word in assets/data/stories.json (English stories) it stores:
  type          "sight" (heart word), "decodable" or "tricky"
  graphemes     letters grouped by sound, e.g. kite -> k i t e(silent)
  phonemes      the CMU sounds for those graphemes (silent ones left out)
  onset / rime  the visual split, e.g. h + ad, sh + ip, str + ong
  keyword/emoji a picture word with the same first sound (hat, sun, shoe)
  rime_say      the rime spelled so text-to-speech says it as a chunk
  needs_review  true when something is uncertain (see review_reasons)

At the end it prints the words that need a human check.
"""

import json
import re
import sys
from pathlib import Path

import cmudict

ROOT = Path(__file__).resolve().parent.parent
STORIES = ROOT / "assets" / "data" / "stories.json"
OUT = ROOT / "assets" / "data" / "phonics.json"

VOWELS = {"AA", "AE", "AH", "AO", "AW", "AY", "EH", "ER", "EY", "IH", "IY",
          "OW", "OY", "UH", "UW"}

# Heart words: learned by sight, not sounded out.
SIGHT = {
    "the", "was", "said", "one", "of", "to", "you", "they", "come", "some",
    "are", "have", "do", "what", "where", "there", "two", "who", "could",
    "would", "should", "does", "your", "were", "their", "again", "any",
    "many", "once", "friend", "friends", "give", "gives", "live", "lived",
    "love", "move", "other", "mother", "another", "a", "i", "put", "from",
    "our", "everyone", "every", "water", "work", "ear",
}

# One keyword per first sound (CMU phonemes of the onset), used for every
# word. Each keyword is checked against CMUdict below.
KEYWORDS = {
    "B": ("ball", "⚽"), "CH": ("chair", "🪑"), "D": ("dog", "🐶"),
    "DH": ("this", "👉"), "F": ("fish", "🐟"), "G": ("goat", "🐐"),
    "HH": ("hat", "🎩"), "JH": ("juice", "🧃"), "K": ("kite", "🪁"),
    "L": ("lion", "🦁"), "M": ("moon", "🌙"), "N": ("nest", "🪺"),
    "P": ("pig", "🐷"), "R": ("rabbit", "🐰"), "S": ("sun", "☀️"),
    "SH": ("shoe", "👟"), "T": ("tiger", "🐯"), "TH": ("thumb", "👍"),
    "V": ("van", "🚐"), "W": ("window", "🪟"), "Y": ("yarn", "🧶"),
    "Z": ("zebra", "🦓"),
    # Blends
    "B L": ("blue", "🔵"), "B R": ("bread", "🍞"), "K L": ("clock", "🕐"),
    "K R": ("crab", "🦀"), "D R": ("drum", "🥁"), "F L": ("flower", "🌸"),
    "F R": ("frog", "🐸"), "G L": ("glove", "🧤"), "G R": ("grapes", "🍇"),
    "P L": ("plane", "✈️"), "P R": ("present", "🎁"), "S K": ("skate", "⛸️"),
    "S L": ("sled", "🛷"), "S M": ("smile", "😊"), "S N": ("snake", "🐍"),
    "S P": ("spoon", "🥄"), "S T": ("star", "⭐"), "S W": ("swan", "🦢"),
    "T R": ("tree", "🌳"), "T W": ("twins", "👯"), "TH R": ("three", "3️⃣"),
    "SH R": ("shrimp", "🦐"), "S P L": ("splash", "💦"),
    "S P R": ("spring", "🌷"), "S T R": ("string", "🧵"),
    "S K R": ("screw", "🔩"), "S K W": ("squid", "🦑"), "K W": ("queen", "👑"),
    # Vowel first sounds
    "AE": ("apple", "🍎"), "EH": ("egg", "🥚"), "IH": ("insect", "🐛"),
    "AA": ("octopus", "🐙"), "AH": ("umbrella", "☂️"), "EY": ("acorn", "🌰"),
    "IY": ("eagle", "🦅"), "AY": ("ice", "🧊"), "OW": ("ocean", "🌊"),
    "AW": ("owl", "🦉"), "OY": ("oyster", "🦪"), "ER": ("earth", "🌍"),
    "AO": ("autumn", "🍂"),
}

# Used instead when the keyword is the word itself ("fish" can't start
# like fish).
ALT_KEYWORDS = {
    "F": ("fox", "🦊"), "K": ("key", "🔑"), "P": ("panda", "🐼"),
    "S M": ("smell", "👃"), "TH R": ("throw", "🥏"), "T R": ("train", "🚂"),
    "S T R": ("straw", "🥤"),
}

# Words with several CMU pronunciations: the one the stories mean.
# (Weak forms like "and" = AH N D are dropped automatically; see choose().)
PREFER = {
    "wind": "W IH N D",      # S06 "The wind was strong" (noun)
    "during": "D UH R IH NG",
    "on": "AA N",
    "when": "W EH N",
    "read": "R IY D",        # S18 uses both "could not read" and "Bolt read"
    "close": "K L OW S",     # S12 "stayed close together"
    "lived": "L IH V D",
    "bought": "B AO T",       # so the rime reads as the word "ought"
    "us": "AH S",            # not "U.S."
    "the": "DH AH",
    "a": "AH",
}
ALWAYS_REVIEW = {}

# Checked by a person: (type to force or None). Their review flag is cleared.
REVIEWED = {
    "during": None, "on": None, "when": None, "mangroves": None,
    "turon": None, "read": None,
    "honest": "tricky", "island": "tricky", "walked": "tricky",
}

# One word read two ways in the same story: (story id, word before it,
# word, pronunciation, how text-to-speech should say it).
OCCURRENCES = [
    ("S18", "not", "read", "R IY D", "reed"),    # "Bolt could not read"
    ("S18", "Bolt", "read", "R EH D", "red"),    # "Bolt read a whole story"
]

# Names and words CMUdict doesn't have (flagged for review).
MANUAL = {
    "pip": "P IH P", "jen": "JH EH N", "jens": "JH EH N Z", "thea": "TH IY AH",
    "lia": "L IY AH", "mia": "M IY AH", "turon": "T UW R AA N",
    "marco": "M AA R K OW", "marcos": "M AA R K OW S",
    "mangroves": "M AE N G R OW V Z",
}

# Letter groups -> sounds, with a cost: 0 = regular phonics, higher = less
# regular. (Contexts like soft c are allowed everywhere; the cheapest
# alignment wins.)
RULES = []


def rule(letters, phonemes, cost=0.0):
    RULES.append((letters, tuple(phonemes.split()), cost))


for g, p in [
    ("b", "B"), ("bb", "B"), ("c", "K"), ("c", "S"), ("ck", "K"), ("cc", "K"),
    ("ch", "CH"), ("tch", "CH"), ("d", "D"), ("dd", "D"), ("f", "F"),
    ("ff", "F"), ("ph", "F"), ("g", "G"), ("gg", "G"), ("dge", "JH"),
    ("h", "HH"), ("j", "JH"), ("k", "K"), ("kn", "N"), ("l", "L"),
    ("ll", "L"), ("m", "M"), ("mm", "M"), ("n", "N"), ("nn", "N"), ("n", "NG"),
    ("ng", "NG"), ("p", "P"), ("pp", "P"), ("qu", "K W"), ("r", "R"),
    ("rr", "R"), ("wr", "R"), ("s", "S"), ("ss", "S"), ("s", "Z"),
    ("sh", "SH"), ("t", "T"), ("tt", "T"), ("th", "TH"), ("th", "DH"),
    ("v", "V"), ("w", "W"), ("wh", "W"), ("x", "K S"), ("y", "Y"), ("z", "Z"),
    ("zz", "Z"), ("ed", "D"), ("ed", "T"), ("ed", "IH D"), ("ed", "AH D"),
    ("le", "AH L"), ("es", "IH Z"), ("es", "AH Z"),
    # vowels
    ("a", "AE"), ("a", "EY"), ("e", "EH"), ("e", "IY"), ("i", "IH"),
    ("i", "AY"), ("o", "AA"), ("o", "OW"), ("o", "AO"), ("u", "AH"),
    ("u", "UW"), ("u", "Y UW"), ("y", "IY"), ("y", "AY"), ("y", "IH"),
    ("ai", "EY"), ("ay", "EY"), ("ee", "IY"), ("ea", "IY"), ("ie", "AY"),
    ("ie", "IY"), ("igh", "AY"), ("oa", "OW"), ("oe", "OW"), ("oo", "UW"),
    ("oo", "UH"), ("ou", "AW"), ("ow", "AW"), ("ow", "OW"), ("oi", "OY"),
    ("oy", "OY"), ("au", "AO"), ("aw", "AO"), ("ew", "UW"), ("ew", "Y UW"),
    ("ue", "UW"), ("ue", "Y UW"), ("ui", "UW"), ("ey", "EY"), ("ey", "IY"),
    ("ei", "EY"),
    # r-controlled
    ("ar", "AA R"), ("or", "AO R"), ("er", "ER"), ("ir", "ER"), ("ur", "ER"),
    ("ear", "ER"), ("ear", "IH R"), ("eer", "IH R"), ("air", "EH R"),
    ("are", "EH R"), ("ore", "AO R"), ("oor", "AO R"), ("our", "AO R"),
    ("our", "AW ER"), ("ar", "ER"), ("or", "ER"), ("ure", "ER"),
    ("ture", "CH ER"),
]:
    rule(g, p)

# Unstressed vowels (schwa) are normal in longer words: cheap.
for g in ["a", "e", "i", "o", "u", "ai", "ou"]:
    rule(g, "AH", 0.3)
rule("le", "L", 0.3)  # only when it isn't l + magic e (smile)
for g, p in [("ch", "K"), ("e", "IH"), ("i", "IY"), ("a", "AA"), ("a", "AO"), ("u", "UH"),
             ("g", "JH"), ("x", "G Z"), ("ea", "EH"), ("o", "UW"),
             ("ou", "UW"), ("al", "AO L")]:
    rule(g, p, 0.5)
# Irregular spellings: the word is "tricky".
for g, p in [("ai", "EH"), ("a", "EH"), ("o", "W AH"), ("ou", "UH"),
             ("ou", "AH"), ("ough", "UW"), ("ough", "AO"), ("ough", "OW"),
             ("ough", "AW"), ("augh", "AO"), ("o", "AH"), ("ie", "EH"),
             ("u", "IH"), ("ea", "EY"), ("oo", "AH"), ("o", "UH"),
             ("wh", "HH"), ("ui", "IH"), ("s", "ZH"), ("i", "Y"), ("eo", "IY"),
             ("wo", "UW"), ("ue", ""), ("gh", ""), ("ol", "OW L"),
             ("al", "AA"), ("ough", "AA"), ("f", "V"), ("ay", "IY")]:
    rule(g, p, 1.0)

SILENT_COST = {"e": 1.5, "h": 2.0, "k": 2.0, "w": 2.0, "b": 2.0, "l": 2.0,
               "t": 2.0, "g": 2.0, "u": 2.0, "a": 2.0, "s": 2.0}


def silent_cost(word, i):
    c = word[i]
    if c == "e" and (i == len(word) - 1 or word[i + 1:] in ("s", "d")):
        return 0.2  # magic / final e (kite, times, waved)
    return SILENT_COST.get(c)


def align(word, phonemes):
    """Cheapest grouping of letters into graphemes for these phonemes.
    Returns (cost, [(letters, phonemes tuple)]) or None."""
    n, m = len(word), len(phonemes)
    best = {(0, 0): (0.0, None, None)}
    for i in range(n + 1):
        for j in range(m + 1):
            if (i, j) not in best:
                continue
            cost = best[(i, j)][0]
            nexts = []
            for letters, ph, c in RULES:
                if word.startswith(letters, i) and tuple(phonemes[j:j + len(ph)]) == ph:
                    nexts.append((i + len(letters), j + len(ph), c, (letters, ph, c)))
            if i < n:
                s = silent_cost(word, i)
                if s is not None:
                    nexts.append((i + 1, j, s, (word[i], (), s)))
            for ni, nj, c, step in nexts:
                if (ni, nj) not in best or best[(ni, nj)][0] > cost + c:
                    best[(ni, nj)] = (cost + c, (i, j), step)
    if (n, m) not in best:
        return None
    steps, key = [], (n, m)
    while best[key][1] is not None:
        _, prev, step = best[key]
        steps.append(step)
        key = prev
    return best[(n, m)][0], steps[::-1]


def strip(p):
    return re.sub(r"\d", "", p)


def first_sound(pron):
    """Sounds before the first vowel, or the first vowel if there are none."""
    out = []
    for p in pron.split():
        if p in VOWELS:
            return " ".join(out) if out else p
        out.append(p)
    return " ".join(out)


def choose(word, prons):
    """Picks the citation form: the pronunciation with the most stressed
    vowels (so "and" is AE N D, not the weak AH N D). Returns (pron, ties)
    where ties are other pronunciations just as strong."""
    def strength(pr):
        return sum(1 for p in pr if p[-1] in "12")
    best = max(strength(pr) for pr in prons)
    strong = list(dict.fromkeys(" ".join(strip(p) for p in pr)
                                for pr in prons if strength(pr) == best))
    return strong[0], strong[1:]


RESPELL = {"AA": "ah", "AE": "a", "AH": "uh", "AO": "aw", "AW": "ow",
           "AY": "eye", "EH": "eh", "ER": "er", "EY": "ay", "IH": "ih",
           "IY": "ee", "OW": "oh", "OY": "oy", "UH": "oo", "UW": "oo"}


# Vowel spellings TTS would read with a different sound than the word
# uses: (letters, sound) -> spelling for TTS.
VOWEL_RESPELL = {
    ("ea", "EH"): "e", ("ea", "EY"): "a", ("ow", "OW"): "o", ("ou", "UW"): "oo",
    ("ou", "UH"): "oo", ("o", "AH"): "u", ("a", "AA"): "o", ("ie", "AY"): "i",
    ("ey", "EY"): "ay", ("ey", "IY"): "ee", ("ew", "UW"): "oo", ("ue", "UW"): "oo",
    ("ui", "UW"): "oo",
}
MAGIC_E = {"i", "a", "o"}  # "i" + consonant + "e" reads as a long vowel


def rime_say(rime, rime_steps, d=None):
    """The rime as text-to-speech should read it: the letters, unless they
    would be read as letter names (one letter, no vowel letter) or with a
    different vowel sound than this word has ("ead" in thread -> "ed")."""
    if not rime_steps:
        return rime
    # A real word that sounds the same ("ought" in bought) reads well.
    want = [p for _, ph, _ in rime_steps for p in ph]
    if d and len(rime) > 1 and any([strip(p) for p in pr] == want for pr in d.get(rime, [])):
        return rime
    if len(rime) == 1 or not re.search("[aeiou]", rime):
        return "".join(RESPELL.get(p, p.lower()) for _, ph, _ in rime_steps for p in ph)
    if rime.endswith("ied") and any("AY" in ph for _, ph, _ in rime_steps):
        return rime[:-3] + "ide"  # tied, tried
    one_syllable = sum(1 for _, ph, _ in rime_steps for p in ph if p in VOWELS) == 1
    out, changed, long_vowel, seen_vowel = "", False, False, False
    for g, ph, _ in rime_steps:
        key = (g, " ".join(ph))
        is_vowel = any(p in VOWELS for p in ph)
        first_vowel = is_vowel and not seen_vowel
        seen_vowel = seen_vowel or is_vowel
        # Only the main (first) vowel; plain "o"/"a" only in short rimes,
        # where they are stressed (won, want), not in "together".
        if g in ("o", "a") and not one_syllable:
            first_vowel = False
        if first_vowel and (g.startswith("ough") or key in VOWEL_RESPELL):
            spelled = VOWEL_RESPELL.get(key) or "".join(RESPELL.get(p, "") for p in ph)
            out += spelled
            changed = True
            long_vowel = long_vowel or (spelled in MAGIC_E and ph and ph[0] in ("AY", "EY", "OW"))
        else:
            out += g
    if not changed:
        return rime
    last_is_consonant = not any(p in VOWELS for p in rime_steps[-1][1])
    if long_vowel and last_is_consonant and not out.endswith("e"):
        out += "e"  # tied -> "ide"
    return out


def build_entry(w, pron, reasons, d, say=None):
    """The phonics.json entry for word [w] said as [pron] (CMU phonemes).
    Adds to [reasons] anything that needs a human check."""
    phonemes = pron.split()
    found = align(w, phonemes)
    if found is None:
        reasons.append("letters and sounds could not be lined up")
        cost, steps = 9.0, [(w, tuple(phonemes), 9.0)]
    else:
        cost, steps = found

    graphemes = [g if ph else f"{g}(silent)" for g, ph, _ in steps]
    sounds = [" ".join(ph) for g, ph, _ in steps if ph]

    # Onset: graphemes before the first vowel sound.
    onset, onset_ph = "", []
    for g, ph, _ in steps:
        if any(p in VOWELS for p in ph):
            break
        onset += g
        onset_ph += [p for p in ph]
    rime = w[len(onset):]
    rime_ph = phonemes[len(onset_ph):]
    n_onset = 0
    for g, ph, _ in steps:
        if any(p in VOWELS for p in ph):
            break
        n_onset += 1
    rime_steps = steps[n_onset:]
    if onset_ph and onset_ph[0] not in VOWELS and any(p in VOWELS for p in onset_ph):
        reasons.append("onset contains a vowel sound")

    if w in SIGHT:
        kind = "sight"
    elif cost <= 0.6 and all(c <= 0.5 for _, _, c in steps):
        kind = "decodable"
    else:
        kind = "tricky"
    if cost >= 2 and kind != "sight":
        reasons.append(f"tricky spelling: {'·'.join(graphemes)} = {' '.join(phonemes)}")

    key = " ".join(onset_ph) if onset_ph else (rime_ph[0] if rime_ph else "")
    kw = KEYWORDS.get(key)
    if kw is None and onset_ph:
        kw = KEYWORDS.get(onset_ph[0])
        if kind != "sight":
            reasons.append(f"no keyword for '{key}'; used the first sound's")
    if kw is None and kind != "sight":
        reasons.append(f"no keyword for first sound '{key}'")
    if kw and kw[0] == w:
        kw = ALT_KEYWORDS.get(key)
        if kw is None and kind != "sight":
            reasons.append("keyword is the word itself and there is no other")

    entry = {
        "type": kind,
        "graphemes": graphemes,
        "phonemes": sounds,
        "onset": onset,
        "rime": rime,
        "rime_say": rime_say(rime, rime_steps, d),
        "onset_phonemes": onset_ph,
        "keyword": kw[0] if kw else None,
        "emoji": kw[1] if kw else None,
        "needs_review": bool(reasons),
    }
    entry["word_say"] = say or w
    forced = REVIEWED.get(w)
    if forced:
        entry["type"] = forced
    return entry


def build(stories, d=None):
    """phonics.json's content for [stories] (the whole library), plus the
    words that need a human check: (data, [(word, reasons)])."""
    d = d or cmudict.dict()
    words = sorted({
        re.sub(r"[^a-z0-9]", "", w["word"].lower())
        for s in stories if s["language"] == "EN" for w in s["words"]
    })

    # Every keyword must really start with its sound.
    for sound, (kw, _) in list(KEYWORDS.items()) + list(ALT_KEYWORDS.items()):
        want = sound.split()
        prons = [[strip(p) for p in pr] for pr in d.get(kw, [])]
        if not any(pr[:len(want)] == want for pr in prons):
            sys.exit(f"Keyword '{kw}' does not start with {sound}: {prons}")

    out, review = {}, []
    for w in words:
        reasons = []
        if w in ALWAYS_REVIEW:
            reasons.append(ALWAYS_REVIEW[w])
        if w in PREFER:
            pron = PREFER[w]
        elif w in d:
            pron, ties = choose(w, d[w])
            # Only ties that change the first sound (the keyword) matter.
            if w not in SIGHT and any(first_sound(t) != first_sound(pron) for t in ties):
                reasons.append(f"several pronunciations {[pron] + ties}; chose {pron}")
        elif w in MANUAL:
            pron = MANUAL[w]
            reasons.append("not in CMUdict; pronunciation added by hand")
        else:
            reasons.append("not in CMUdict and no manual entry")
            out[w] = {"type": "tricky", "graphemes": list(w), "phonemes": [],
                      "onset": "", "rime": w, "rime_say": w,
                      "onset_phonemes": [], "keyword": None, "emoji": None,
                      "needs_review": True, "review_reasons": reasons}
            review.append((w, reasons))
            continue

        entry = build_entry(w, pron, reasons, d)
        if w in REVIEWED:
            reasons.clear()
        entry["needs_review"] = bool(reasons)
        if reasons:
            entry["review_reasons"] = reasons
            review.append((w, reasons))
        out[w] = entry

    # Per-occurrence overrides, keyed "story:position".
    occurrences = {}
    for story_id, before, word, pron, say in OCCURRENCES:
        story = next((s for s in stories if s["id"] == story_id), None)
        if story is None:
            continue
        sw = story["words"]
        found = [sw[i]["position"] for i in range(1, len(sw))
                 if re.sub(r"[^a-z]", "", sw[i]["word"].lower()) == word
                 and re.sub(r"[^a-z]", "", sw[i - 1]["word"].lower()) == before.lower()]
        if len(found) != 1:
            sys.exit(f"{story_id}: expected one '{before} {word}', found {found}")
        entry = {"word": word, **build_entry(word, pron, [], d, say=say)}
        entry["needs_review"] = False
        occurrences[f"{story_id}:{found[0]}"] = entry

    data = {
        "_about": "Generated by tools/gen_phonics.py from the CMU Pronouncing "
                  "Dictionary. Re-run it after adding stories; hand edits "
                  "are overwritten.",
        "keywords": {k: {"word": v[0], "emoji": v[1]} for k, v in KEYWORDS.items()},
        "words": out,
        "occurrences": occurrences,
    }
    return data, review


def write(data, path=OUT):
    path.write_text(json.dumps(data, ensure_ascii=False, indent=1) + "\n", encoding="utf-8")


def main():
    stories = json.loads(STORIES.read_text(encoding="utf-8"))
    data, review = build(stories)
    write(data)
    out = data["words"]
    types = {}
    for e in out.values():
        types[e["type"]] = types.get(e["type"], 0) + 1
    print(f"Wrote {len(out)} words to {OUT.relative_to(ROOT)}: {types}")
    print(f"\n{len(review)} words need review:")
    for w, reasons in review:
        print(f"  {w}: {'; '.join(reasons)}")


if __name__ == "__main__":
    main()
