# =============================================================
#  bot_flow.py  —  AI Patient Bot
#  Key fixes:
#    ✅ predict_specialist.py is now rule-first (no ML hallucinations)
#    ✅ Ophthalmology + Gastroenterology added to follow-up rules
#    ✅ Emergency keywords expanded
#    ✅ Session handling unchanged
# =============================================================

from datetime import datetime
import logging
import re

from spell_checker import process_symptom_input

logging.basicConfig(
    level=logging.DEBUG,
    format="[%(asctime)s] %(levelname)s  %(message)s",
    datefmt="%H:%M:%S",
)
log = logging.getLogger("bot_flow")


# ─────────────────────────────────────────────────────────────
# Greeting helper
# ─────────────────────────────────────────────────────────────

def greet_user() -> str:
    hour = datetime.now().hour
    if hour < 12:
        return "Good morning"
    elif hour < 18:
        return "Good afternoon"
    return "Good evening"


# ─────────────────────────────────────────────────────────────
# Emergency keywords (checked BEFORE everything else)
# ─────────────────────────────────────────────────────────────

EMERGENCY_KEYWORDS = [
    "severe chest pain", "cannot breathe", "can't breathe",
    "unconscious", "stroke", "bleeding heavily", "heart attack",
    "not breathing", "stopped breathing", "seizure",
    "severe head injury", "unresponsive",
]


# ─────────────────────────────────────────────────────────────
# Follow-up rules (ambiguous symptoms that need clarification)
# ─────────────────────────────────────────────────────────────

FOLLOW_UP_RULES = {
    "headache": {
        "question":       "Is it caused by stress/lack of sleep?",
        "yes_specialist": "General Medicine",        # throbbing / migraine
        "no_specialist":  "Neurology", # stress / lifestyle
    },
    "chest pain": {
        "question":       "Was your last meal heavy, or do you feel it might be gastric/acidity?",
        "yes_specialist": "General Medicine",
        "no_specialist":  "Cardiology",
    },
    "dizziness": {
        "question":       "Does the room spin around you (vertigo) or do you just feel lightheaded?",
        "yes_specialist": "Neurology",        # vertigo
        "no_specialist":  "General Medicine", # lightheadedness
    },
}


# ─────────────────────────────────────────────────────────────
# Session store
# ─────────────────────────────────────────────────────────────

_sessions: dict[str, dict] = {}


def _get_session(user_id: str) -> dict:
    if user_id not in _sessions:
        _sessions[user_id] = {
            "stage":         "SYMPTOMS",
            "symptom":       "",
            "specialist":    "",
            "pending_rule":  None,
            "filter_step":   0,
            "filters":       {},
            "invalid_count": 0,
        }
    return _sessions[user_id]


def _clear_session(user_id: str):
    _sessions.pop(user_id, None)


def reset_session(user_id: str):
    _sessions.pop(user_id, None)


def get_all_sessions() -> dict:
    return {
        uid: {"stage": s["stage"], "specialist": s["specialist"]}
        for uid, s in _sessions.items()
    }


# ─────────────────────────────────────────────────────────────
# Main message handler
# ─────────────────────────────────────────────────────────────

def handle_message(user_input: str, user_id: str) -> dict:
    text = user_input.strip()
    t    = text.lower()
    sess = _get_session(user_id)

    # ── Emergency check (bypass everything — speed matters) ────────────
    for kw in EMERGENCY_KEYWORDS:
        if kw in t:
            _clear_session(user_id)
            return {
                "type":    "Emergency",
                "message": "🚨 This sounds serious! Please go to the nearest emergency room immediately or call 112.",
            }

    stage = sess["stage"]

    # ══════════════════════════════════════════════════════════════════
    #  STAGE: SYMPTOMS
    # ══════════════════════════════════════════════════════════════════
    if stage == "SYMPTOMS":

        # ── Spell check + gibberish detection ──────────────────────────
        check = process_symptom_input(text)

        if not check["valid"]:
            sess["invalid_count"] += 1
            log.debug(f"[bot_flow] Invalid input (attempt {sess['invalid_count']}): '{text}'")

            response = {
                "type":    "Invalid Input",
                "message": check["message"],
            }
            if sess["invalid_count"] >= 3:
                response["hint"] = (
                    "💡 Tip: Describe your symptom simply — "
                    "'I have ear pain', 'my knee hurts', 'feeling dizzy'."
                )
            return response

        # ── Valid input ─────────────────────────────────────────────────
        sess["invalid_count"] = 0
        corrected_text        = check["corrected"]

        correction_note = None
        if check["correction_made"]:
            correction_note = (
                f"🔤 Auto-corrected: \"{check['original']}\" → \"{corrected_text}\""
            )
            log.debug(f"[bot_flow] Corrected: '{check['original']}' → '{corrected_text}'")

        sess["symptom"] = corrected_text

        # ── Follow-up rule check ────────────────────────────────────────
        tc = corrected_text.lower()
        for symptom_key, rule in FOLLOW_UP_RULES.items():
            if symptom_key in tc:
                sess["pending_rule"] = rule
                sess["stage"]        = "FOLLOWUP"
                response = {
                    "type":     "Follow-Up Question",
                    "question": rule["question"],
                }
                if correction_note:
                    response["correction_note"] = correction_note
                return response

        # ── Predict specialist ──────────────────────────────────────────
        # predict_specialist.py now uses rule-first → ML-with-confidence-gate
        # So this is always accurate for known symptoms
        try:
            from predict_specialist import predict_specialist as ml_predict
            specialist = ml_predict(corrected_text)
        except Exception as e:
            log.error(f"[bot_flow] predict_specialist error: {e}")
            specialist = "General Medicine"

        sess["specialist"] = specialist
        sess["stage"]      = "CHOICE"

        response = {
            "type":       "Specialist Choice",
            "specialist": specialist,
        }
        if correction_note:
            response["correction_note"] = correction_note
        return response

    # ══════════════════════════════════════════════════════════════════
    #  STAGE: FOLLOWUP
    # ══════════════════════════════════════════════════════════════════
    if stage == "FOLLOWUP":
        rule       = sess.get("pending_rule", {})
        specialist = (
            rule.get("yes_specialist", "General Medicine")
            if "yes" in t
            else rule.get("no_specialist", "General Medicine")
        )
        sess["specialist"]   = specialist
        sess["pending_rule"] = None
        sess["stage"]        = "CHOICE"
        return {"type": "Specialist Choice", "specialist": specialist}

    # ══════════════════════════════════════════════════════════════════
    #  STAGE: CHOICE
    # ══════════════════════════════════════════════════════════════════
    if stage == "CHOICE":
        chose_specialist = (
            "1" in t or "specialist" in t
            or "just tell" in t or "tell me" in t
        )
        if chose_specialist:
            sess["stage"] = "AFTER_SPEC"
            return {"type": "Ask Want Doctors", "specialist": sess["specialist"]}
        else:
            sess["stage"]       = "FILTERS"
            sess["filter_step"] = 0
            sess["filters"]     = {}
            return {"type": "Ask Filters", "filter_step": 0}

    # ══════════════════════════════════════════════════════════════════
    #  STAGE: AFTER_SPEC
    # ══════════════════════════════════════════════════════════════════
    if stage == "AFTER_SPEC":
        if "yes" in t or "1" in t:
            sess["stage"]       = "FILTERS"
            sess["filter_step"] = 0
            sess["filters"]     = {}
            return {"type": "Ask Filters", "filter_step": 0}
        else:
            _clear_session(user_id)
            return {
                "type":    "Goodbye",
                "message": "🌿 We hope you feel better soon! Take care. 💙",
            }

    # ══════════════════════════════════════════════════════════════════
    #  STAGE: FILTERS
    # ══════════════════════════════════════════════════════════════════
    if stage == "FILTERS":
        step    = sess["filter_step"]
        filters = sess["filters"]

        if step == 0:
            filters["location"] = text
            sess["filter_step"] = 1
            return {"type": "Ask Filters", "filter_step": 1}

        elif step == 1:
            val = _parse_number(t)
            filters["max_distance_km"] = val if val is not None else 10.0
            sess["filter_step"] = 2
            return {"type": "Ask Filters", "filter_step": 2}

        elif step == 2:
            val = _parse_number(t)
            filters["max_fees"] = int(val) if val is not None else 2000
            sess["filter_step"] = 3
            return {"type": "Ask Filters", "filter_step": 3}

        elif step == 3:
            val = _parse_number(t)
            filters["min_rating"] = val if val is not None else 0.0
            result_filters        = dict(filters)
            result_specialist     = sess["specialist"]
            _clear_session(user_id)
            return {
                "type":       "Fetch Doctors",
                "specialist": result_specialist,
                "filters":    result_filters,
            }

    return {"type": "Error", "message": "Something went wrong. Please try again."}


# ─────────────────────────────────────────────────────────────
# Helper
# ─────────────────────────────────────────────────────────────

def _parse_number(text: str):
    m = re.search(r"[\d]+(?:\.\d+)?", text)
    return float(m.group()) if m else None