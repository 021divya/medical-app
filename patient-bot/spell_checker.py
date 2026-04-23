# =============================================================
#  spell_checker.py  —  SymSpell integration for AI Patient Bot
#  Handles:
#    1. Spell correction using SymSpell
#    2. Invalid / gibberish symptom detection (char-level)
#    3. Symptom keyword validation (semantic-level)  ← KEY FIX
#    4. Symptom vocabulary built from bot's own SYMPTOM_MAP
# =============================================================

import re
import logging
from pathlib import Path

log = logging.getLogger("spell_checker")

# ── Try to import SymSpell ────────────────────────────────────────────────
try:
    from symspellpy import SymSpell, Verbosity
    SYMSPELL_AVAILABLE = True
except ImportError:
    SYMSPELL_AVAILABLE = False
    log.warning("symspellpy not installed. Run: pip install symspellpy")


# ═════════════════════════════════════════════════════════════════════════
#  SYMPTOM VOCABULARY
#  Must mirror SYMPTOM_MAP in bot_flow.py.
#  Split into two groups:
#    SYMPTOM_KEYWORDS      → used to build SymSpell dictionary
#    VALID_SYMPTOM_TOKENS  → used for post-correction validation
# ═════════════════════════════════════════════════════════════════════════

SYMPTOM_KEYWORDS: list[str] = [
    # Dermatology
    "skin", "rash", "itch", "itching", "acne", "eczema", "pimple", "allergy",
    # ENT
    "ear", "hearing", "throat", "nose", "sinusitis", "tonsil", "sneezing",
    # Orthopaedics
    "joint", "knee", "bone", "fracture", "back pain", "spine", "shoulder",
    "ortho", "ligament", "muscle", "ankle",
    # Cardiology
    "heart", "palpitation", "cardiac", "chest", "blood pressure", "bp",
    # Gynecology
    "period", "menstrual", "pregnancy", "uterus", "ovary", "pcod", "pcos",
    "vaginal", "gynec", "women", "female", "miscarriage",
    # Urology
    "urine", "urinate", "urination", "urge", "urology",
    "kidney", "bladder", "urinary", "prostate", "stone",
    "frequent urination", "burning urination", "painful urination",
    "continuous urge to urinate", "urge to urinate", "pee", "peeing",
    # Psychiatry
    "mental", "anxiety", "depression", "stress", "panic", "insomnia",
    "sleep", "mood", "phobia", "ocd",
    # Pediatrics
    "child", "baby", "infant", "toddler", "pediatric", "kids", "newborn",
    # Neurology
    "nerve", "seizure", "epilepsy", "migraine", "memory", "dizziness",
    "paralysis", "brain", "numbness", "tremor",
    # General Medicine
    "fever", "cold", "flu", "weakness", "fatigue", "body ache", "infection",
    "cough", "stomach", "digestion", "nausea", "vomit", "vomiting", "diarrhea",
    "diabetes", "sugar", "thyroid", "asthma", "wheeze", "lung",
    "abdomen", "gas", "acidity", "pain", "swelling", "breathless", "breathing",
    "headache", "head", "dizzy", "nauseated", "sick", "sore", "runny",
    # Common patient phrasing
    "hurt", "hurting", "aching", "ache", "burning", "tight", "tightness",
    "discharge", "bleeding", "bleed", "swollen", "redness", "red",
    "lump", "bump", "wound", "cut", "bruise", "cramp", "cramps",
    "constipation", "bloating", "bloated", "pus", "sweat", "sweating",
    "chills", "shiver", "shivering", "ringing", "vision", "blurry",
    "jaundice", "yellow", "pale", "weight", "appetite", "loss",
    # Descriptive symptom qualifiers — patients say these WITH symptoms
    # e.g. "continuous urge to urinate", "difficulty breathing", "unable to sleep"
    "continuous", "frequent", "difficulty", "unable", "painful", "severe",
    "mild", "chronic", "acute", "sudden", "recurring", "persistent",
    "excessive", "reduced", "increased", "decreased", "irregular",
    "urge", "pressure", "heaviness", "stiffness", "tenderness",
    "itchy", "flaky", "scaly", "dry", "oily", "crusty",
    "palpitations", "irregular heartbeat", "shortness of breath",
    "loss of appetite", "loss of weight", "hair loss", "hair fall",
    "high fever", "low fever", "mild fever", "body pain",
]

# ── Flat set of individual tokens for fast lookup ────────────────────────
VALID_SYMPTOM_TOKENS: set[str] = set()
for phrase in SYMPTOM_KEYWORDS:
    for word in phrase.split():
        VALID_SYMPTOM_TOKENS.add(word.lower())

# ── Full multi-word phrases for substring matching ───────────────────────
VALID_SYMPTOM_PHRASES: list[str] = [
    p.lower() for p in SYMPTOM_KEYWORDS if " " in p
]

# ── Stopwords that should NOT count as valid symptoms on their own ────────
STOPWORDS: set[str] = {
    "i", "me", "my", "have", "has", "had", "am", "is", "are", "was",
    "the", "a", "an", "and", "or", "but", "in", "on", "at", "to",
    "feel", "feeling", "some", "bit", "little", "very", "really",
    "slightly", "since", "for", "days", "weeks", "day", "week",
    "been", "getting", "got", "get", "please", "help",
    "hello", "hi", "hey", "doctor", "sir", "madam",
    # NOTE: words like "continuous", "frequent", "urge", "difficulty",
    # "unable", "painful" are intentionally NOT here — they are valid
    # symptom descriptors (e.g. "continuous urge to urinate")
}


def _contains_valid_symptom(text: str) -> bool:
    """
    Returns True if the text contains at least one recognised symptom keyword.

    Two checks:
      1. Any multi-word symptom phrase is a substring of text
         e.g. "back pain", "blood pressure"
      2. Any single symptom token appears as a whole word in text,
         and is NOT a pure stopword
    """
    t = text.lower().strip()

    # Check 1 — multi-word phrases
    for phrase in VALID_SYMPTOM_PHRASES:
        if phrase in t:
            return True

    # Check 2 — individual tokens (whole-word boundary match)
    tokens = set(re.findall(r"\b[a-z]+\b", t))
    medical_tokens = tokens - STOPWORDS
    if medical_tokens & VALID_SYMPTOM_TOKENS:
        return True

    return False


# ─────────────────────────────────────────────────────────────────────────
#  GIBBERISH DETECTION  (character-level, runs BEFORE spell correction)
#  Catches: "agsb", "zxcvbn", "aaaaaaa", "12345", "!@#$"
# ─────────────────────────────────────────────────────────────────────────

_MIN_VOWEL_RATIO  = 0.15
_MAX_REPEAT_RATIO = 0.60
_ONLY_NON_ALPHA   = re.compile(r"^[^a-zA-Z]+$")
_MIN_LENGTH       = 3


def _is_gibberish(text: str) -> bool:
    t = text.strip().lower()

    if not t:
        return True
    if _ONLY_NON_ALPHA.match(t):         # pure numbers / symbols
        return True
    if len(t) < _MIN_LENGTH:
        return True

    chars = t.replace(" ", "")
    if not chars:
        return True

    # No vowels in a long string
    vowel_count = sum(1 for c in chars if c in "aeiou")
    if len(chars) > 4 and vowel_count / len(chars) < _MIN_VOWEL_RATIO:
        return True

    # Single character dominates
    most_common = max(chars.count(c) for c in set(chars))
    if len(chars) > 4 and most_common / len(chars) > _MAX_REPEAT_RATIO:
        return True

    # Classic keyboard mash patterns
    for pat in [
        r"^[qwrtypsdfghjklzxcvbnm]{5,}$",   # consonant wall
        r"^(.)\1{3,}$",                        # aaaaa / zzzzz
        r"^(qw|wq|zx|xz|asdf|qwer|zxcv)",    # keyboard walk
    ]:
        if re.match(pat, chars):
            return True

    return False


# ═════════════════════════════════════════════════════════════════════════
#  SYMSPELL ENGINE
# ═════════════════════════════════════════════════════════════════════════

class SymSpellChecker:
    def __init__(self):
        self._sym = None
        if SYMSPELL_AVAILABLE:
            self._load()

    def _load(self):
        try:
            import symspellpy
            sym = SymSpell(max_dictionary_edit_distance=2, prefix_length=7)

            pkg_dir     = Path(symspellpy.__file__).parent
            dict_path   = pkg_dir / "frequency_dictionary_en_82_765.txt"
            bigram_path = pkg_dir / "frequency_bigramdictionary_en_243_342.txt"

            if dict_path.exists():
                sym.load_dictionary(str(dict_path), term_index=0, count_index=1)
            if bigram_path.exists():
                sym.load_bigram_dictionary(str(bigram_path), term_index=0, count_index=2)

            # Inject symptom words at very high priority so SymSpell
            # always prefers medical terms over common English words
            for word in VALID_SYMPTOM_TOKENS:
                sym.create_dictionary_entry(word, 10_000_000)

            self._sym = sym
            log.info(f"✅ SymSpell loaded — {len(VALID_SYMPTOM_TOKENS)} symptom tokens injected")

        except Exception as e:
            log.error(f"SymSpell failed to load: {e}")
            self._sym = None

    def correct(self, text: str) -> tuple[str, bool]:
        if self._sym is None:
            return text, False
        try:
            suggestions = self._sym.lookup_compound(text, max_edit_distance=2)
            if not suggestions:
                return text, False
            corrected     = suggestions[0].term
            was_corrected = corrected.lower().strip() != text.lower().strip()
            return corrected, was_corrected
        except Exception as e:
            log.warning(f"SymSpell correction failed: {e}")
            return text, False


# ── Singleton instance ────────────────────────────────────────────────────
_checker = SymSpellChecker()


# ═════════════════════════════════════════════════════════════════════════
#  INVALID MESSAGES  (rotated so bot doesn't repeat itself)
# ═════════════════════════════════════════════════════════════════════════

_INVALID_MESSAGES = [
    (
        "❌ I couldn't recognise that as a valid symptom.\n"
        "Please describe what you're feeling — for example:\n"
        "• fever  • headache  • chest pain  • joint pain  • cough"
    ),
    (
        "❌ That doesn't seem to be a recognisable symptom.\n"
        "Could you rephrase? Try something like:\n"
        "• 'I have a sore throat'  • 'I feel dizzy'  • 'my stomach hurts'"
    ),
    (
        "❌ I couldn't identify a valid symptom in your input.\n"
        "Please enter a clear symptom such as:\n"
        "• back pain  • anxiety  • nausea  • skin rash  • breathlessness"
    ),
]

_invalid_idx = 0


def get_invalid_message() -> str:
    global _invalid_idx
    msg = _INVALID_MESSAGES[_invalid_idx % len(_INVALID_MESSAGES)]
    _invalid_idx += 1
    return msg


# ═════════════════════════════════════════════════════════════════════════
#  PUBLIC API  —  called by bot_flow.py
# ═════════════════════════════════════════════════════════════════════════

def process_symptom_input(raw_text: str) -> dict:
    """
    Full 3-step validation pipeline:

      Step 1 — Gibberish detection (char-level)
               Catches: "agsb", "zxcvbn", "1234", "!!!"
               → reject immediately, no correction attempted

      Step 2 — SymSpell correction
               Catches: "fevr" → "fever", "diarea" → "diarrhea", "stomch" → "stomach"
               → corrects typos before validation

      Step 3 — Symptom keyword presence check  ← THE KEY FIX
               Catches: "brainless", "hello", "I am fine", "random words"
               → even valid English words are rejected if they contain
                  no recognised symptom keyword

    Returns:
      {
        "valid":           bool,
        "corrected":       str,    # use this for all downstream processing
        "original":        str,
        "correction_made": bool,
        "message":         str | None,   # set only when valid=False
      }
    """
    original = raw_text.strip()

    # ── Step 1: Gibberish guard ───────────────────────────────────────────
    if _is_gibberish(original):
        log.debug(f"[SpellCheck] GIBBERISH rejected: '{original}'")
        return _invalid(original)

    # ── Step 2: Spell correction ──────────────────────────────────────────
    corrected, was_corrected = _checker.correct(original)
    if was_corrected:
        log.debug(f"[SpellCheck] Corrected: '{original}' → '{corrected}'")

    # ── Step 3: Symptom keyword presence check ────────────────────────────
    #
    #  This is the root-cause fix for the original bug.
    #
    #  predict_specialist() ALWAYS returns a specialist (defaults to
    #  "General Medicine") — it has no concept of "invalid input".
    #  So we must validate BEFORE reaching it.
    #
    #  "brainless" → SymSpell keeps it as "brainless" (valid English word)
    #               → but "brainless" contains no symptom keyword → REJECT
    #
    #  "I have fever" → contains "fever" → PASS
    #  "my knee hurts" → contains "knee" + "hurt" → PASS
    #  "agsb" → caught by Step 1 already
    #
    if not _contains_valid_symptom(corrected):
        log.debug(f"[SpellCheck] NO SYMPTOM KEYWORD in: '{corrected}'")
        return _invalid(original)

    # ── All checks passed ─────────────────────────────────────────────────
    return {
        "valid":           True,
        "corrected":       corrected,
        "original":        original,
        "correction_made": was_corrected,
        "message":         None,
    }


def _invalid(original: str) -> dict:
    return {
        "valid":           False,
        "corrected":       original,
        "original":        original,
        "correction_made": False,
        "message":         get_invalid_message(),
    }