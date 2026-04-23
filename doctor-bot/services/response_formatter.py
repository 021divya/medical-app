# ==============================
# response_formatter.py
# Converts parameters + abnormal dict
# into a structured JSON-friendly list
# for Flutter to render with colors
# ==============================

from abnormal_detector import NORMAL_RANGES


def format_report_response(
    filename: str,
    parameters: dict,
    abnormal: dict,
    summary: str,
) -> dict:
    """
    Returns the full API response dict with a `results` list.
    Each item has: param, value, status, normal_range.
    Flutter uses `status` to decide color.
    """

    results = []

    for param, value in parameters.items():
        status = abnormal.get(param, "UNKNOWN")

        # Build human-readable range string
        if param in NORMAL_RANGES:
            lo, hi = NORMAL_RANGES[param]
            normal_range = f"{lo} – {hi}"
        else:
            normal_range = "N/A"

        results.append({
            "param":        _pretty_label(param),   # "Hemoglobin", "HbA1c" etc.
            "value":        value,
            "status":       status,                  # "NORMAL" | "LOW" | "HIGH" | "UNKNOWN"
            "normal_range": normal_range,
        })

    return {
        "filename":       filename,
        "parameters":     parameters,        # kept for backward compat
        "abnormal_values": abnormal,         # kept for backward compat
        "results":        results,           # ← Flutter uses this
        "summary":        summary,
    }


# ==============================
# PRETTY LABELS
# ==============================
_LABEL_MAP = {
    "hemoglobin":           "Hemoglobin",
    "rbc":                  "RBC",
    "wbc":                  "WBC",
    "platelets":            "Platelets",
    "hematocrit":           "Hematocrit (PCV)",
    "mcv":                  "MCV",
    "mch":                  "MCH",
    "mchc":                 "MCHC",
    "rdw":                  "RDW",
    "mpv":                  "MPV",
    "neutrophils":          "Neutrophils",
    "lymphocytes":          "Lymphocytes",
    "monocytes":            "Monocytes",
    "eosinophils":          "Eosinophils",
    "basophils":            "Basophils",
    "glucose":              "Glucose",
    "hba1c":                "HbA1c",
    "cholesterol":          "Total Cholesterol",
    "hdl":                  "HDL Cholesterol",
    "ldl":                  "LDL Cholesterol",
    "triglycerides":        "Triglycerides",
    "vldl":                 "VLDL",
    "creatinine":           "Creatinine",
    "urea":                 "Blood Urea (BUN)",
    "uric_acid":            "Uric Acid",
    "sgot":                 "SGOT (AST)",
    "sgpt":                 "SGPT (ALT)",
    "alp":                  "Alkaline Phosphatase",
    "bilirubin":            "Total Bilirubin",
    "bilirubin_direct":     "Direct Bilirubin",
    "bilirubin_indirect":   "Indirect Bilirubin",
    "total_protein":        "Total Protein",
    "albumin":              "Albumin",
    "globulin":             "Globulin",
    "tsh":                  "TSH",
    "t3":                   "T3",
    "t4":                   "T4",
    "free_t3":              "Free T3",
    "free_t4":              "Free T4",
    "sodium":               "Sodium",
    "potassium":            "Potassium",
    "chloride":             "Chloride",
    "calcium":              "Calcium",
    "serum_iron":           "Serum Iron",
    "tibc":                 "TIBC",
    "ferritin":             "Ferritin",
    "vitamin_b12":          "Vitamin B12",
    "vitamin_d":            "Vitamin D",
}

def _pretty_label(key: str) -> str:
    return _LABEL_MAP.get(key, key.replace("_", " ").title())