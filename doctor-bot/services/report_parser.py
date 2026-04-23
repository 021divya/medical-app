import re


# ==============================
# KNOWN PARAMETER ALIASES
# Maps any OCR variant → canonical key
# ==============================
PARAMETER_ALIASES = {
    # Hemoglobin
    "hemoglobin": "hemoglobin",
    "hgb": "hemoglobin",
    "hb": "hemoglobin",

    # WBC
    "wbc": "wbc",
    "white blood cell": "wbc",
    "white blood cells": "wbc",
    "leukocytes": "wbc",
    "total wbc": "wbc",
    "total leucocyte count": "wbc",
    "tlc": "wbc",

    # RBC
    "rbc": "rbc",
    "red blood cell": "rbc",
    "red blood cells": "rbc",
    "erythrocytes": "rbc",
    "total rbc": "rbc",

    # Platelets
    "platelets": "platelets",
    "platelet count": "platelets",
    "plt": "platelets",
    "thrombocytes": "platelets",

    # Hematocrit / PCV
    "hematocrit": "hematocrit",
    "pcv": "hematocrit",
    "packed cell volume": "hematocrit",
    "hct": "hematocrit",

    # MCV / MCH / MCHC
    "mcv": "mcv",
    "mean corpuscular volume": "mcv",
    "mch": "mch",
    "mean corpuscular hemoglobin": "mch",
    "mchc": "mchc",
    "mean corpuscular hemoglobin concentration": "mchc",

    # Cholesterol
    "cholesterol": "cholesterol",
    "total cholesterol": "cholesterol",
    "chol": "cholesterol",

    # Blood sugar
    "glucose": "glucose",
    "blood glucose": "glucose",
    "fasting glucose": "glucose",
    "fbs": "glucose",
    "random blood sugar": "glucose",
    "rbs": "glucose",
    "blood sugar": "glucose",

    # Creatinine
    "creatinine": "creatinine",
    "serum creatinine": "creatinine",
    "s. creatinine": "creatinine",

    # Urea / BUN
    "urea": "urea",
    "blood urea": "urea",
    "bun": "urea",
    "blood urea nitrogen": "urea",

    # Uric acid
    "uric acid": "uric_acid",
    "serum uric acid": "uric_acid",

    # Liver enzymes
    "sgot": "sgot",
    "ast": "sgot",
    "aspartate aminotransferase": "sgot",
    "sgpt": "sgpt",
    "alt": "sgpt",
    "alanine aminotransferase": "sgpt",
    "alkaline phosphatase": "alp",
    "alp": "alp",
    "bilirubin": "bilirubin",
    "total bilirubin": "bilirubin",
    "s. bilirubin": "bilirubin",
    "direct bilirubin": "bilirubin_direct",
    "indirect bilirubin": "bilirubin_indirect",

    # Thyroid
    "tsh": "tsh",
    "thyroid stimulating hormone": "tsh",
    "t3": "t3",
    "t4": "t4",
    "free t3": "free_t3",
    "free t4": "free_t4",
    "ft3": "free_t3",
    "ft4": "free_t4",

    # Proteins
    "total protein": "total_protein",
    "albumin": "albumin",
    "globulin": "globulin",

    # Electrolytes
    "sodium": "sodium",
    "na": "sodium",
    "potassium": "potassium",
    "k": "potassium",
    "chloride": "chloride",
    "cl": "chloride",
    "calcium": "calcium",
    "ca": "calcium",

    # Lipid panel
    "hdl": "hdl",
    "hdl cholesterol": "hdl",
    "ldl": "ldl",
    "ldl cholesterol": "ldl",
    "triglycerides": "triglycerides",
    "tg": "triglycerides",
    "vldl": "vldl",

    # CBC extras
    "neutrophils": "neutrophils",
    "lymphocytes": "lymphocytes",
    "monocytes": "monocytes",
    "eosinophils": "eosinophils",
    "basophils": "basophils",
    "rdw": "rdw",
    "rdw-cv": "rdw",
    "mpv": "mpv",
    "mean platelet volume": "mpv",

    # HbA1c
    "hba1c": "hba1c",
    "glycated hemoglobin": "hba1c",
    "glycosylated hemoglobin": "hba1c",

    # Iron studies
    "serum iron": "serum_iron",
    "iron": "serum_iron",
    "tibc": "tibc",
    "ferritin": "ferritin",

    # Vitamins
    "vitamin b12": "vitamin_b12",
    "vit b12": "vitamin_b12",
    "b12": "vitamin_b12",
    "vitamin d": "vitamin_d",
    "vit d": "vitamin_d",
    "25-oh vitamin d": "vitamin_d",
}


def _normalize_key(raw: str) -> str | None:
    """Lowercase + strip → lookup in aliases."""
    cleaned = raw.lower().strip().rstrip(":")
    # remove extra whitespace runs
    cleaned = re.sub(r"\s+", " ", cleaned)
    return PARAMETER_ALIASES.get(cleaned)


def extract_parameters(text: str) -> dict:
    """
    Robustly extracts lab parameters from OCR/PDF text.
    Handles:
      - varied separators  (: / - / whitespace / |)
      - extra spaces, tabs
      - values with decimals
      - values followed by units (g/dL, mg/dL, %, etc.)
      - lines where label and value are tab/pipe-separated (table layout)
    """
    if not text or not text.strip():
        return {}

    parameters = {}

    # -------------------------------------------------------
    # STRATEGY 1: line-by-line pattern match
    # label  [sep]  numeric_value  [optional unit]
    # -------------------------------------------------------
    LINE_PATTERN = re.compile(
        r"^([\w\s\.\-/]+?)"            # group 1 — parameter label
        r"[\s\t]*[:\-|][\s\t]*"        # separator
        r"(\d+\.?\d*)"                 # group 2 — numeric value
        r"(?:\s*[a-zA-Z/%µ][^\n]*)?$", # optional unit / trailing text
        re.IGNORECASE
    )

    for line in text.splitlines():
        line = line.strip()
        if not line:
            continue

        m = LINE_PATTERN.match(line)
        if m:
            raw_label = m.group(1).strip()
            raw_value = m.group(2)
            canonical = _normalize_key(raw_label)
            if canonical and canonical not in parameters:
                try:
                    parameters[canonical] = float(raw_value)
                except ValueError:
                    pass

    # -------------------------------------------------------
    # STRATEGY 2: inline search for known aliases
    # Catches cases like "Hb 12.4 g/dL" with no separator
    # -------------------------------------------------------
    for alias, canonical in PARAMETER_ALIASES.items():
        if canonical in parameters:
            continue  # already found

        # escape alias for regex (handles "25-OH Vitamin D" etc.)
        escaped = re.escape(alias)
        pattern = re.compile(
            rf"\b{escaped}\b"            # alias word-boundary
            rf"[\s\t]*[:\-|]?[\s\t]*"   # optional separator
            rf"(\d+\.?\d*)",             # numeric value
            re.IGNORECASE
        )
        m = pattern.search(text)
        if m:
            try:
                parameters[canonical] = float(m.group(1))
            except ValueError:
                pass

    return parameters