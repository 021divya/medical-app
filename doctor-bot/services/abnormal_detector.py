# ==============================
# NORMAL RANGES
# (min, max) — units as commonly reported
# ==============================
NORMAL_RANGES = {
    # CBC
    "hemoglobin":       (12.0,  17.5),   # g/dL  (women 12–16, men 13.5–17.5)
    "rbc":              (3.8,   5.8),    # million/µL
    "wbc":              (4000,  11000),  # cells/µL
    "platelets":        (150000,450000), # /µL
    "hematocrit":       (36.0,  50.0),   # %
    "mcv":              (80.0,  100.0),  # fL
    "mch":              (27.0,  33.0),   # pg
    "mchc":             (32.0,  36.0),   # g/dL
    "rdw":              (11.5,  14.5),   # %
    "mpv":              (7.5,   12.5),   # fL

    # Differential (%)
    "neutrophils":      (40.0,  75.0),
    "lymphocytes":      (20.0,  45.0),
    "monocytes":        (2.0,   10.0),
    "eosinophils":      (1.0,   6.0),
    "basophils":        (0.0,   1.0),

    # Glucose
    "glucose":          (70.0,  100.0),  # mg/dL fasting
    "hba1c":            (4.0,   5.6),    # %

    # Lipids
    "cholesterol":      (0.0,   200.0),  # mg/dL
    "hdl":              (40.0,  60.0),   # mg/dL
    "ldl":              (0.0,   100.0),  # mg/dL
    "triglycerides":    (0.0,   150.0),  # mg/dL
    "vldl":             (2.0,   30.0),   # mg/dL

    # Kidney
    "creatinine":       (0.6,   1.2),    # mg/dL
    "urea":             (7.0,   20.0),   # mg/dL (BUN)
    "uric_acid":        (2.4,   7.0),    # mg/dL

    # Liver
    "sgot":             (0.0,   40.0),   # U/L
    "sgpt":             (0.0,   40.0),   # U/L
    "alp":              (44.0,  147.0),  # U/L
    "bilirubin":        (0.2,   1.2),    # mg/dL total
    "bilirubin_direct": (0.0,   0.3),    # mg/dL
    "bilirubin_indirect":(0.2,  0.9),    # mg/dL
    "total_protein":    (6.0,   8.3),    # g/dL
    "albumin":          (3.5,   5.0),    # g/dL
    "globulin":         (2.0,   3.5),    # g/dL

    # Thyroid
    "tsh":              (0.4,   4.0),    # mIU/L
    "t3":               (80.0,  200.0),  # ng/dL
    "t4":               (5.0,   12.0),   # µg/dL
    "free_t3":          (2.3,   4.2),    # pg/mL
    "free_t4":          (0.8,   1.8),    # ng/dL

    # Electrolytes
    "sodium":           (136.0, 145.0),  # mEq/L
    "potassium":        (3.5,   5.0),    # mEq/L
    "chloride":         (98.0,  107.0),  # mEq/L
    "calcium":          (8.5,   10.5),   # mg/dL

    # Iron studies
    "serum_iron":       (60.0,  170.0),  # µg/dL
    "tibc":             (250.0, 370.0),  # µg/dL
    "ferritin":         (12.0,  300.0),  # ng/mL

    # Vitamins
    "vitamin_b12":      (200.0, 900.0),  # pg/mL
    "vitamin_d":        (20.0,  50.0),   # ng/mL
}


def detect_abnormal(parameters: dict) -> dict:
    """
    Returns a dict of {param: "LOW" | "HIGH" | "NORMAL" | "UNKNOWN"}
    for every parameter passed in.
    """
    abnormal = {}

    for param, value in parameters.items():
        if param not in NORMAL_RANGES:
            abnormal[param] = "UNKNOWN"
            continue

        min_val, max_val = NORMAL_RANGES[param]

        if value < min_val:
            abnormal[param] = "LOW"
        elif value > max_val:
            abnormal[param] = "HIGH"
        else:
            abnormal[param] = "NORMAL"

    return abnormal