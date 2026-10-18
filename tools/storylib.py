"""Shared helpers for the story tools: word tagging, book difficulty and
validation of assets/data/stories.json. Used by add_stories.py,
story_difficulty.py and check_stories.py (run those, not this file).

Book difficulty is AGENT_SPEC §11. Its numbers live here, not in the app,
because only these tools compute it; the app just reads `difficulty`.
"""

import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
DATA = ROOT / "assets" / "data"

LANGUAGES = ("EN", "FIL")
QUESTION_TYPES = ("Literal", "Inferential")
QUESTIONS_PER_STORY = 3
CHOICES_PER_QUESTION = 3

# ---- Book difficulty (AGENT_SPEC §11) --------------------------------------
# Each part goes from 0 (at the first number) to 1 (at the second).
LENGTH_WORDS = (15, 90)
SENTENCE_WORDS = (3.5, 11)
SYLLABLES_PER_WORD = {"EN": (1.0, 1.5), "FIL": (1.6, 2.25)}
HARD_WORD_SHARE = {"EN": (0.08, 0.26), "FIL": (0.22, 0.46)}
WEIGHTS = {"length": 0.30, "sentences": 0.25, "syllables": 0.20, "hard_words": 0.25}
SIGHT_WEIGHT = 0.5  # a sight word counts as half a hard word

# Filipino word types from patterns (no phonics.json entries for Filipino).
FIL_SIGHT = {"FIL-SW", "FIL-MGA"}
FIL_DECODABLE = {"FIL-CV", "FIL-NG", "FIL-DIP"}


def paths(data_dir=None):
    d = Path(data_dir) if data_dir else DATA
    return {
        "stories": d / "stories.json",
        "phonics": d / "phonics.json",
        "patterns": d / "sound_patterns.json",
    }


def load_json(path):
    return json.loads(Path(path).read_text(encoding="utf-8"))


def write_json(path, data):
    Path(path).write_text(json.dumps(data, ensure_ascii=False, indent=1) + "\n",
                          encoding="utf-8")


# ---- Words ------------------------------------------------------------------

def tokens(text):
    """The story's words as written (one per space-separated token), the
    same split the app uses."""
    return text.split()


def word_of(token):
    """A token without the punctuation around it ("cat." -> "cat"); inner
    apostrophes and hyphens stay ("Let's", "araw-araw")."""
    return re.sub(r"^[^\w]+|[^\w]+$", "", token)


def phonics_key(word):
    """How phonics.json names a word (tools/gen_phonics.py)."""
    return re.sub(r"[^a-z0-9]", "", word.lower())


def sentences(text):
    """Sentences end with . ! or ? (maybe followed by a closing quote)."""
    return [s for s in re.split(r"(?<=[.!?])[\"”’']?\s+", text.strip()) if s.strip()]


def clamp01(x):
    return max(0.0, min(1.0, x))


def part(x, lo_hi):
    lo, hi = lo_hi
    return clamp01((x - lo) / (hi - lo))


def word_type(story, w, phonics):
    """"sight", "decodable" or "tricky" for one story word."""
    if story["language"] == "EN":
        occ = phonics.get("occurrences", {}).get(f"{story['id']}:{w['position']}")
        entry = occ or phonics.get("words", {}).get(phonics_key(w["word"]))
        return entry["type"] if entry else "tricky"
    pats = set(w["patterns"])
    if pats & FIL_SIGHT:
        return "sight"
    if pats <= FIL_DECODABLE:
        return "decodable"
    return "tricky"


def difficulty_parts(story, phonics):
    """The four parts of a book's difficulty, each 0–1, plus the raw numbers."""
    words = story["words"]
    n = len(words)
    lang = story["language"]
    per_sentence = n / max(1, len(sentences(story["text"])))
    syllables = sum(w["syllables"] for w in words) / n
    types = [word_type(story, w, phonics) for w in words]
    hard = (types.count("tricky") + SIGHT_WEIGHT * types.count("sight")) / n
    return {
        "length": part(n, LENGTH_WORDS),
        "sentences": part(per_sentence, SENTENCE_WORDS),
        "syllables": part(syllables, SYLLABLES_PER_WORD[lang]),
        "hard_words": part(hard, HARD_WORD_SHARE[lang]),
    }, {
        "words": n,
        "words_per_sentence": round(per_sentence, 1),
        "syllables_per_word": round(syllables, 2),
        "sight": round(types.count("sight") / n, 2),
        "decodable": round(types.count("decodable") / n, 2),
        "tricky": round(types.count("tricky") / n, 2),
    }


def book_difficulty(story, phonics):
    """0–100 (AGENT_SPEC §11)."""
    parts, _ = difficulty_parts(story, phonics)
    return round(100 * sum(WEIGHTS[k] * parts[k] for k in WEIGHTS))


# ---- Tagging new words ------------------------------------------------------

EN_SIGHT = {
    # tagged EN-SW in the starter stories
    "a", "all", "and", "are", "at", "but", "by", "can", "do", "for", "from",
    "get", "got", "had", "has", "have", "he", "her", "his", "i", "in", "into",
    "is", "it", "not", "of", "on", "one", "said", "she", "so", "the", "they",
    "to", "too", "two", "up", "was", "we", "with", "you",
    # more heart / high-frequency words
    "an", "as", "be", "come", "could", "does", "go", "here", "him", "if",
    "me", "my", "no", "or", "our", "put", "says", "should", "some", "their",
    "there", "this", "what", "where", "who", "would", "your", "were",
}
FIL_SIGHT_WORDS = {
    "ang", "at", "ay", "ito", "kami", "may", "na", "ng", "ni", "pa", "rin",
    "sa", "si", "sila", "siya", "din", "daw", "raw", "ba", "po", "ko", "mo",
    "ka", "kay", "sina", "nina", "kina", "ang", "iyan", "iyon", "tayo",
}

EN_BLEND3 = ("str", "spr", "scr", "spl", "squ", "thr", "shr")
EN_BLEND2 = ("bl", "br", "cl", "cr", "dr", "fl", "fr", "gl", "gr", "pl", "pr",
             "sc", "sk", "sl", "sm", "sn", "sp", "st", "sw", "tr", "tw")
FIL_AFFIX = re.compile(r"^(ipinag|pinag|nag|mag|pag|naka|maka|paki|ipina|ibi|ini)"
                       r"|^[bcdfghklmnprstwy](um|in)[aeiou]")


def load_patterns(path):
    """{code: (difficulty, order)} from sound_patterns.json."""
    return {p["code"]: (p["difficulty"], i) for i, p in enumerate(load_json(path))}


def en_syllables(w, cmu):
    key = phonics_key(w)
    prons = cmu.get(key) if cmu else None
    if prons:
        return sum(1 for p in prons[0] if p[-1].isdigit())
    groups = re.findall(r"[aeiouy]+", key)
    n = len(groups)
    if key.endswith("e") and not key.endswith(("le", "ee")) and n > 1:
        n -= 1  # silent final e
    return max(1, n)


def fil_syllables(w):
    return max(1, len(re.findall(r"[aeiou]", w.lower())))


def en_patterns(w, syllables):
    k = phonics_key(w)
    out = []
    if k in EN_SIGHT:
        out.append("EN-SW")
    if k.startswith(EN_BLEND3):
        out.append("EN-BL3")
    elif k.startswith(EN_BLEND2):
        out.append("EN-BL")
    if "th" in k:
        out.append("EN-TH")
    if "sh" in k:
        out.append("EN-SH")
    if "ch" in k:
        out.append("EN-CH")
    ing = k.endswith("ing") and re.search(r"[aeiouy]", k[:-3])
    if k.endswith("ng") and not ing:
        out.append("EN-NG")
    if ing:
        out.append("EN-ING")
    if len(k) >= 5 and k.endswith("ed") and not k.endswith("eed") and re.search(r"[aeiouy]", k[:-2]):
        out.append("EN-ED")
    if re.search(r"ai|ay|ee|ea|oa|oo|oe|ui|ei", k):
        out.append("EN-VT")
    if re.search(r"ou|ow", k):
        out.append("EN-OU")
    if re.search(r"[aeiou]r", k):
        out.append("EN-RC")
    if re.search(r"[aeiou][^aeiouwxy]e$", k) and len(k) >= 3 and k not in EN_SIGHT:
        out.append("EN-ME")
    if syllables >= 3:
        out.append("EN-ML")
    if not out:
        out.append("EN-SV")
    return out


def fil_patterns(w, syllables):
    k = w.lower()
    out = []
    if k == "mga":
        return ["FIL-MGA"]
    if k in FIL_SIGHT_WORDS:
        out.append("FIL-SW")
    if "ng" in k:
        out.append("FIL-NG")
    if re.search(r"(ay|aw|oy|uy|iw)(?![aeiou])", k):
        out.append("FIL-DIP")
    # Kambal-katinig: a cluster at the start (plato, trabaho). Inside a word
    # two consonants usually split into two syllables (nag·la·ro), so only
    # the loanword clusters dr/tr/pr/br count there (Isidro).
    if re.match(r"^[bcdfgkpst][lr]", k) or re.search(r"(?<=[aeiou])(dr|tr|pr|br)(?=[aeiou])", k):
        out.append("FIL-KK")
    if FIL_AFFIX.search(k.replace("-", "")):
        out.append("FIL-AFX")
    if syllables >= 4 or "-" in k:
        out.append("FIL-ML")
    if not [p for p in out if p != "FIL-SW"] and "FIL-SW" not in out:
        out.append("FIL-CV")
    return out


def word_difficulty(patterns, syllables, pattern_info):
    hardest = max(pattern_info[p][0] for p in patterns)
    return round(min(1.0, hardest + 0.03 * (syllables - 1)), 2)


def lexicon(stories):
    """Tags already used in the library, by (language, lowercase word), so a
    word is always tagged the same way."""
    lex = {}
    for s in stories:
        for w in s["words"]:
            lex.setdefault((s["language"], w["word"].lower()), {
                "patterns": w["patterns"],
                "primary_pattern": w["primary_pattern"],
                "syllables": w["syllables"],
                "difficulty": w["difficulty"],
            })
    return lex


def tag_word(word, language, pattern_info, lex=None, cmu=None):
    """The word's tags for stories.json, and whether they were made by rules
    (True) or reused from the library (False)."""
    known = (lex or {}).get((language, word.lower()))
    if known:
        return dict(known), False
    if language == "EN":
        syl = en_syllables(word, cmu)
        pats = en_patterns(word, syl)
    else:
        syl = fil_syllables(word)
        pats = fil_patterns(word, syl)
    pats = sorted(set(pats), key=lambda p: pattern_info[p][1])
    primary = max(pats, key=lambda p: (pattern_info[p][0], -pattern_info[p][1]))
    return {
        "patterns": pats,
        "primary_pattern": primary,
        "syllables": syl,
        "difficulty": word_difficulty(pats, syl, pattern_info),
    }, True


# ---- Validation -------------------------------------------------------------

def validate(stories, phonics, pattern_info, check_difficulty=True):
    """Every problem in the library, as a list of strings (empty = fine)."""
    errors = []
    ids = set()
    for si, s in enumerate(stories):
        sid = s.get("id", f"#{si + 1}")
        where = f"{sid}"
        for key in ("id", "title", "language", "text", "words", "questions", "difficulty"):
            if key not in s:
                errors.append(f"{where}: missing '{key}'")
        if not re.fullmatch(r"S\d{2,}", str(s.get("id", ""))):
            errors.append(f"{where}: id should look like S21")
        if sid in ids:
            errors.append(f"{where}: duplicate id")
        ids.add(sid)
        if not str(s.get("title", "")).strip():
            errors.append(f"{where}: empty title")
        lang = s.get("language")
        if lang not in LANGUAGES:
            errors.append(f"{where}: language must be EN or FIL, not {lang!r}")
            continue
        toks = tokens(s.get("text", ""))
        words = s.get("words", [])
        if len(toks) != len(words):
            errors.append(f"{where}: {len(toks)} words in the text but {len(words)} tagged words")
        for i, (t, w) in enumerate(zip(toks, words)):
            at = f"{where} word {i + 1} ({t})"
            if w.get("position") != i + 1:
                errors.append(f"{at}: position should be {i + 1}")
            if w.get("word") != word_of(t):
                errors.append(f"{at}: word should be {word_of(t)!r}, not {w.get('word')!r}")
            pats = w.get("patterns") or []
            if not pats:
                errors.append(f"{at}: no patterns")
            for p in pats:
                if p not in pattern_info:
                    errors.append(f"{at}: unknown pattern {p}")
                elif not p.startswith(lang + "-"):
                    errors.append(f"{at}: pattern {p} is not a {lang} pattern")
            if pats and all(p in pattern_info for p in pats):
                if w.get("primary_pattern") not in pats:
                    errors.append(f"{at}: primary_pattern must be one of its patterns")
                elif pattern_info[w["primary_pattern"]][0] != max(pattern_info[p][0] for p in pats):
                    errors.append(f"{at}: primary_pattern should be the hardest pattern")
            if not isinstance(w.get("syllables"), int) or w["syllables"] < 1:
                errors.append(f"{at}: syllables must be a whole number ≥ 1")
            if not isinstance(w.get("difficulty"), (int, float)) or not 0 <= w["difficulty"] <= 1:
                errors.append(f"{at}: word difficulty must be 0–1")
            if lang == "EN" and phonics_key(w.get("word", "")) not in phonics.get("words", {}):
                errors.append(f"{at}: not in phonics.json (run tools/gen_phonics.py)")
        if not sentences(s.get("text", "")) or not re.search(r"[.!?][\"”’']?\s*$", s.get("text", "")):
            errors.append(f"{where}: the text should end with . ! or ?")

        qs = s.get("questions", [])
        if len(qs) != QUESTIONS_PER_STORY:
            errors.append(f"{where}: {len(qs)} questions, needs exactly {QUESTIONS_PER_STORY}")
        for qi, q in enumerate(qs):
            at = f"{where} question {qi + 1}"
            if q.get("id") != f"{sid}-Q{qi + 1}":
                errors.append(f"{at}: id should be {sid}-Q{qi + 1}")
            if not str(q.get("question", "")).strip():
                errors.append(f"{at}: empty question")
            if q.get("type") not in QUESTION_TYPES:
                errors.append(f"{at}: type must be Literal or Inferential")
            ch = q.get("choices", [])
            if len(ch) != CHOICES_PER_QUESTION:
                errors.append(f"{at}: {len(ch)} answers, needs exactly {CHOICES_PER_QUESTION}")
            right = [c for c in ch if c.get("correct") is True]
            if len(right) != 1:
                errors.append(f"{at}: needs exactly one correct answer, has {len(right)}")
            elif q.get("answer") != right[0].get("text"):
                errors.append(f"{at}: 'answer' must equal the correct choice's text")
            for c in ch:
                if not str(c.get("text", "")).strip() or not str(c.get("emoji", "")).strip():
                    errors.append(f"{at}: every answer needs text and a picture (emoji)")
            if len({c.get("text") for c in ch}) != len(ch):
                errors.append(f"{at}: two answers are the same")

        d = s.get("difficulty")
        if not isinstance(d, int) or not 0 <= d <= 100:
            errors.append(f"{where}: difficulty must be a whole number 0–100")
        elif check_difficulty and not errors_for(errors, where) and d != book_difficulty(s, phonics):
            errors.append(f"{where}: difficulty {d} is out of date (now {book_difficulty(s, phonics)}); "
                          "run tools/story_difficulty.py")
    return errors


def errors_for(errors, where):
    return any(e.startswith(where + ":") or e.startswith(where + " ") for e in errors)


def review_words(stories, phonics, only=None):
    """English words phonics.json flags for a human check: [(word, reasons)].
    [only] limits it to these phonics keys."""
    out = []
    for k, e in phonics.get("words", {}).items():
        if e.get("needs_review") and (only is None or k in only):
            out.append((k, e.get("review_reasons", [])))
    return out
