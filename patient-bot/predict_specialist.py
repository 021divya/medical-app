import joblib
import os
from sentence_transformers import SentenceTransformer

# ─────────────────────────────────────────────────────────────
# Model paths
# ─────────────────────────────────────────────────────────────
BASE_DIR           = os.path.dirname(os.path.abspath(__file__))
CLASSIFIER_PATH    = os.path.join(BASE_DIR, "model", "specialist_classifier.pkl")
LABEL_ENCODER_PATH = os.path.join(BASE_DIR, "model", "label_encoder.pkl")

# ─────────────────────────────────────────────────────────────
# Load models
# ─────────────────────────────────────────────────────────────
try:
    clf           = joblib.load(CLASSIFIER_PATH)
    label_encoder = joblib.load(LABEL_ENCODER_PATH)
    embedder      = SentenceTransformer("all-MiniLM-L6-v2")
    print("✅ ML specialist model loaded")
except Exception as e:
    print("⚠️ ML model not found:", e)
    clf = embedder = label_encoder = None


# ─────────────────────────────────────────────────────────────
# RULE-BASED MAP  (highest priority — always checked first)
# This is the GROUND TRUTH layer. ML is only used for cases
# not covered here.
# ─────────────────────────────────────────────────────────────
RULE_MAP = [
    # ENT  ← fixes "ear pain → cardiologist" bug
    (["ear", "hearing", "ear pain", "ear ache", "earache",
      "ear discharge", "ear infection", "ringing in ear", "tinnitus",
      "throat", "sore throat", "throat pain", "tonsil", "tonsillitis",
      "nose", "nasal", "sinusitis", "sinus", "sneezing", "runny nose",
      "blocked nose", "stuffy nose", "cold", "hoarse", "hoarseness",
      "voice", "laryngitis", "adenoid"],                                    "ENT"),

    # Dermatology
    (["skin", "rash", "itch", "itching", "acne", "eczema", "pimple",
      "psoriasis", "dermatitis", "hives", "urticaria", "dandruff",
      "hair fall", "hair loss", "alopecia", "nail", "fungal infection",
      "ringworm", "wart", "mole", "pigmentation", "dark spots"],           "Dermatology"),

    # Orthopaedics
    (["joint pain", "knee pain", "bone", "fracture", "back pain",
      "spine", "shoulder pain", "ligament", "ankle", "foot pain",
      "hip pain", "elbow pain", "wrist pain", "neck pain", "slip disc",
      "sciatica", "arthritis", "gout", "spondylitis", "muscle pain",
      "muscle cramp", "tendon", "orthopedic"],                             "Orthopaedics"),

    # Cardiology  ← only truly cardiac symptoms
    (["chest pain", "heart", "palpitation", "cardiac", "heart attack",
      "irregular heartbeat", "blood pressure", "hypertension",
      "heart failure", "angina", "arrhythmia", "ecg", "cholesterol",
      "high bp", "low bp"],                                                "Cardiology"),

    # Gynecology
    (["period", "menstrual", "menstruation", "irregular periods",
      "pregnancy", "uterus", "ovary", "pcod", "pcos",
      "vaginal", "vaginal discharge", "gynec", "miscarriage",
      "menopause", "fertility", "ovulation", "cervical"],                  "Gynecology"),

    # Urology
    (["urine", "urinate", "urination", "urinary", "burning urine",
      "frequent urination", "urge to urinate", "kidney", "kidney stone",
      "bladder", "prostate", "uti", "nephrology",
      "pee", "peeing", "dysuria"],                                         "Urology"),

    # Psychiatry
    (["mental", "anxiety", "depression", "stress", "panic attack",
      "insomnia", "sleep disorder", "mood", "phobia", "ocd",
      "bipolar", "schizophrenia", "hallucination", "suicidal",
      "trauma", "ptsd", "adhd", "eating disorder"],                        "Psychiatry"),

    # Pediatrics
    (["child", "baby", "infant", "toddler", "pediatric",
      "kids", "newborn", "vaccination", "growth"],                         "Pediatrics"),

    # Neurology
    (["nerve", "seizure", "epilepsy", "migraine", "memory loss",
      "dizziness", "vertigo", "paralysis", "brain", "numbness",
      "tremor", "parkinson", "alzheimer", "stroke", "fainting",
      "blackout", "multiple sclerosis", "neuropathy", "tingling"],         "Neurology"),

    # Ophthalmology
    (["eye", "vision", "blurry vision", "eye pain", "red eye",
      "watery eye", "cataract", "glaucoma", "retina", "conjunctivitis",
      "squint", "spectacles", "eye infection"],                            "Ophthalmology"),


    # General Medicine — true fallback only
    (["stomach", "digestion", "nausea", "vomit", "vomiting", "diarrhea",
      "constipation", "abdomen", "gas", "acidity", "bloating",
      "stomach pain", "abdominal pain", "ibs", "crohn", "colitis",
      "liver", "hepatitis", "jaundice", "gallbladder", "ulcer",
      "endoscopy", "gastric","fever", "flu", "weakness", "fatigue", "body ache", "infection",
      "cough", "diabetes", "sugar", "thyroid", "asthma",
      "wheeze", "lung", "breathless", "breathing difficulty",
      "weight loss", "weight gain", "appetite loss", "general",
      "checkup", "routine"],                                               "General Medicine"),
]


def _rule_based(text: str) -> str | None:
    """
    Returns specialist if ANY rule keyword matches, else None.
    Longer/more specific phrases checked first to avoid partial clashes.
    e.g. 'ear pain' should not match 'pain' in Orthopaedics.
    """
    t = text.lower()
    # Sort by longest keyword first so specific phrases win
    for keywords, spec in RULE_MAP:
        sorted_kw = sorted(keywords, key=len, reverse=True)
        for kw in sorted_kw:
            # Whole-phrase boundary match
            import re
            pattern = r"\b" + re.escape(kw) + r"\b"
            if re.search(pattern, t):
                return spec
    return None


# ─────────────────────────────────────────────────────────────
# ML confidence threshold
# Below this → distrust ML and use rule-based instead
# ─────────────────────────────────────────────────────────────
ML_CONFIDENCE_THRESHOLD = 0.55


def predict_specialist(symptoms_text: str) -> str:
    """
    3-layer prediction strategy:

    Layer 1 — Rule-based (highest priority)
              If ANY known symptom keyword matches → use it.
              This prevents ML hallucinations for common symptoms.

    Layer 2 — ML model with confidence gate
              Only used when rules don't match.
              If confidence < threshold → fall back to Layer 3.

    Layer 3 — General Medicine (safe fallback)
    """
    text = symptoms_text.strip().lower()

    # ── Layer 1: Rule-based ───────────────────────────────────
    rule_result = _rule_based(text)
    if rule_result:
        print(f"[predict] Rule-based → {rule_result}")
        return rule_result

    # ── Layer 2: ML model with confidence gate ────────────────
    if clf is not None and embedder is not None:
        try:
            emb         = embedder.encode([text])
            proba       = clf.predict_proba(emb)[0]
            confidence  = proba.max()
            pred_index  = proba.argmax()
            specialist  = label_encoder.inverse_transform([pred_index])[0]

            print(f"[predict] ML → {specialist} (confidence: {confidence:.2f})")

            if confidence >= ML_CONFIDENCE_THRESHOLD:
                return specialist
            else:
                print(f"[predict] ML confidence too low ({confidence:.2f}) → General Medicine")
        except Exception as e:
            print(f"[predict] ML error: {e}")

    # ── Layer 3: Safe fallback ────────────────────────────────
    print("[predict] Fallback → General Medicine")
    return "General Medicine"