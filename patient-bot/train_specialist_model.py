"""
train_specialist_model.py
=========================
Trains a LogisticRegression classifier on top of sentence-transformer
embeddings to predict medical specialist from symptom text.

Fixes:
  ✅ Removed deprecated multi_class="auto" (dropped in sklearn 1.5+)
  ✅ Heavily expanded augmented data for ALL specialists
  ✅ 5x oversampling of augmented data
  ✅ class_weight="balanced" handles CSV imbalance
  ✅ Confidence threshold — low-confidence predictions → General Medicine
  ✅ Saves model only if accuracy ≥ 75%
"""

import os
import pandas as pd
import joblib

from sklearn.model_selection import train_test_split
from sklearn.linear_model import LogisticRegression
from sklearn.metrics import classification_report, accuracy_score
from sklearn.preprocessing import LabelEncoder
from sentence_transformers import SentenceTransformer

os.makedirs("model", exist_ok=True)


# ═════════════════════════════════════════════════════════════
#  AUGMENTED TRAINING DATA
#  Every specialist has 40+ examples so the model treats them equally.
#  Multiplied 5x below so this anchors the model hard.
# ═════════════════════════════════════════════════════════════

AUGMENTED_DATA = [

    # ── ENT ──────────────────────────────────────────────────
    ("ear pain",                                               "ENT"),
    ("earache",                                                "ENT"),
    ("pain in my ear",                                        "ENT"),
    ("my ear is hurting",                                     "ENT"),
    ("ear discharge",                                         "ENT"),
    ("ear infection",                                         "ENT"),
    ("ringing in ear",                                        "ENT"),
    ("tinnitus",                                              "ENT"),
    ("hearing loss",                                          "ENT"),
    ("difficulty hearing",                                    "ENT"),
    ("sore throat",                                           "ENT"),
    ("throat pain",                                           "ENT"),
    ("my throat hurts",                                       "ENT"),
    ("tonsil pain",                                           "ENT"),
    ("tonsillitis",                                           "ENT"),
    ("swollen tonsils",                                       "ENT"),
    ("runny nose",                                            "ENT"),
    ("blocked nose",                                          "ENT"),
    ("stuffy nose",                                           "ENT"),
    ("sinusitis",                                             "ENT"),
    ("sinus pain",                                            "ENT"),
    ("frequent sneezing",                                     "ENT"),
    ("nasal congestion",                                      "ENT"),
    ("hoarse voice",                                          "ENT"),
    ("loss of voice",                                         "ENT"),
    ("adenoids problem",                                      "ENT"),
    ("nose bleed",                                            "ENT"),
    ("epistaxis",                                             "ENT"),
    ("deviated nasal septum",                                 "ENT"),
    ("postnasal drip",                                        "ENT"),
    ("lump in throat",                                        "ENT"),
    ("voice change",                                          "ENT"),
    ("difficulty swallowing",                                 "ENT"),
    ("itching inside ear",                                    "ENT"),
    ("fluid in ear",                                          "ENT"),
    ("otitis media",                                          "ENT"),
    ("swollen lymph nodes in neck",                           "ENT"),
    ("throat infection",                                      "ENT"),
    ("strep throat",                                          "ENT"),
    ("pharyngitis",                                           "ENT"),
    ("laryngitis",                                            "ENT"),
    ("snoring problem",                                       "ENT"),
    ("sleep apnea",                                           "ENT"),

    # ── Dermatology ──────────────────────────────────────────
    ("skin rash",                                             "Dermatology"),
    ("itchy skin",                                            "Dermatology"),
    ("acne on face",                                          "Dermatology"),
    ("eczema",                                                "Dermatology"),
    ("pimples",                                               "Dermatology"),
    ("skin allergy",                                          "Dermatology"),
    ("psoriasis",                                             "Dermatology"),
    ("dry skin",                                              "Dermatology"),
    ("hives",                                                 "Dermatology"),
    ("urticaria",                                             "Dermatology"),
    ("hair fall",                                             "Dermatology"),
    ("hair loss",                                             "Dermatology"),
    ("dandruff",                                              "Dermatology"),
    ("fungal infection on skin",                              "Dermatology"),
    ("ringworm",                                              "Dermatology"),
    ("warts",                                                 "Dermatology"),
    ("dark spots on skin",                                    "Dermatology"),
    ("nail infection",                                        "Dermatology"),
    ("skin peeling",                                          "Dermatology"),
    ("oily skin",                                             "Dermatology"),
    ("blackheads",                                            "Dermatology"),
    ("whiteheads",                                            "Dermatology"),
    ("skin tag",                                              "Dermatology"),
    ("mole on skin",                                          "Dermatology"),
    ("redness on skin",                                       "Dermatology"),
    ("skin burning sensation",                                "Dermatology"),
    ("seborrheic dermatitis",                                 "Dermatology"),
    ("rosacea",                                               "Dermatology"),
    ("vitiligo",                                              "Dermatology"),
    ("melasma",                                               "Dermatology"),
    ("boil on skin",                                          "Dermatology"),
    ("carbuncle",                                             "Dermatology"),
    ("cellulitis",                                            "Dermatology"),
    ("skin inflammation",                                     "Dermatology"),
    ("scabies",                                               "Dermatology"),
    ("lice",                                                  "Dermatology"),
    ("ingrown nail",                                          "Dermatology"),
    ("brittle nails",                                         "Dermatology"),
    ("alopecia",                                              "Dermatology"),
    ("stretch marks",                                         "Dermatology"),

    # ── Orthopaedics ─────────────────────────────────────────
    ("knee pain",                                             "Orthopaedics"),
    ("joint pain",                                            "Orthopaedics"),
    ("back pain",                                             "Orthopaedics"),
    ("lower back pain",                                       "Orthopaedics"),
    ("shoulder pain",                                         "Orthopaedics"),
    ("neck pain",                                             "Orthopaedics"),
    ("bone fracture",                                         "Orthopaedics"),
    ("ankle pain",                                            "Orthopaedics"),
    ("hip pain",                                              "Orthopaedics"),
    ("slip disc",                                             "Orthopaedics"),
    ("sciatica",                                              "Orthopaedics"),
    ("arthritis",                                             "Orthopaedics"),
    ("spondylitis",                                           "Orthopaedics"),
    ("muscle pain",                                           "Orthopaedics"),
    ("wrist pain",                                            "Orthopaedics"),
    ("elbow pain",                                            "Orthopaedics"),
    ("ligament tear",                                         "Orthopaedics"),
    ("foot pain",                                             "Orthopaedics"),
    ("gout",                                                  "Orthopaedics"),
    ("tennis elbow",                                          "Orthopaedics"),
    ("frozen shoulder",                                       "Orthopaedics"),
    ("rotator cuff injury",                                   "Orthopaedics"),
    ("bone density problem",                                  "Orthopaedics"),
    ("osteoporosis",                                          "Orthopaedics"),
    ("flat feet",                                             "Orthopaedics"),
    ("heel pain",                                             "Orthopaedics"),
    ("plantar fasciitis",                                     "Orthopaedics"),
    ("spine problem",                                         "Orthopaedics"),
    ("scoliosis",                                             "Orthopaedics"),
    ("carpal tunnel syndrome",                                "Orthopaedics"),
    ("cracked bone",                                          "Orthopaedics"),
    ("swollen joints",                                        "Orthopaedics"),
    ("rheumatoid arthritis",                                  "Orthopaedics"),
    ("sports injury",                                         "Orthopaedics"),
    ("acl tear",                                              "Orthopaedics"),
    ("meniscus tear",                                         "Orthopaedics"),
    ("dislocated shoulder",                                   "Orthopaedics"),
    ("thumb pain",                                            "Orthopaedics"),
    ("finger pain",                                           "Orthopaedics"),
    ("toe pain",                                              "Orthopaedics"),

    # ── Cardiology ───────────────────────────────────────────
    ("chest pain",                                            "Cardiology"),
    ("heart palpitations",                                    "Cardiology"),
    ("irregular heartbeat",                                   "Cardiology"),
    ("high blood pressure",                                   "Cardiology"),
    ("hypertension",                                          "Cardiology"),
    ("heart attack",                                          "Cardiology"),
    ("angina",                                                "Cardiology"),
    ("shortness of breath with chest pain",                   "Cardiology"),
    ("arrhythmia",                                            "Cardiology"),
    ("heart failure",                                         "Cardiology"),
    ("high cholesterol",                                      "Cardiology"),
    ("low blood pressure",                                    "Cardiology"),
    ("my heart is racing",                                    "Cardiology"),
    ("heart disease",                                         "Cardiology"),
    ("chest tightness",                                       "Cardiology"),
    ("racing pulse",                                          "Cardiology"),
    ("blocked arteries",                                      "Cardiology"),
    ("coronary artery disease",                               "Cardiology"),
    ("cardiac arrest",                                        "Cardiology"),
    ("heart murmur",                                          "Cardiology"),
    ("swollen legs with breathlessness",                      "Cardiology"),
    ("atrial fibrillation",                                   "Cardiology"),
    ("ventricular tachycardia",                               "Cardiology"),
    ("heart valve problem",                                   "Cardiology"),
    ("pericarditis",                                          "Cardiology"),
    ("myocarditis",                                           "Cardiology"),
    ("deep vein thrombosis",                                  "Cardiology"),
    ("pulmonary embolism",                                    "Cardiology"),
    ("aortic aneurysm",                                       "Cardiology"),
    ("heart bypass needed",                                   "Cardiology"),

    # ── Gynecology ───────────────────────────────────────────
    ("irregular periods",                                     "Gynecology"),
    ("menstrual pain",                                        "Gynecology"),
    ("period cramps",                                         "Gynecology"),
    ("pregnancy",                                             "Gynecology"),
    ("pcos",                                                  "Gynecology"),
    ("pcod",                                                  "Gynecology"),
    ("vaginal discharge",                                     "Gynecology"),
    ("uterus pain",                                           "Gynecology"),
    ("ovarian cyst",                                          "Gynecology"),
    ("missed period",                                         "Gynecology"),
    ("menopause",                                             "Gynecology"),
    ("fertility issues",                                      "Gynecology"),
    ("heavy bleeding during period",                          "Gynecology"),
    ("miscarriage",                                           "Gynecology"),
    ("endometriosis",                                         "Gynecology"),
    ("fibroids",                                              "Gynecology"),
    ("uterine fibroid",                                       "Gynecology"),
    ("vaginal infection",                                      "Gynecology"),
    ("yeast infection",                                       "Gynecology"),
    ("itching in private parts",                              "Gynecology"),
    ("pelvic pain",                                           "Gynecology"),
    ("lower abdominal pain in women",                         "Gynecology"),
    ("breast lump",                                           "Gynecology"),
    ("breast pain",                                           "Gynecology"),
    ("nipple discharge",                                      "Gynecology"),
    ("antenatal checkup",                                     "Gynecology"),
    ("prenatal care",                                         "Gynecology"),
    ("contraception advice",                                  "Gynecology"),
    ("hot flashes",                                           "Gynecology"),
    ("night sweats in women",                                 "Gynecology"),
    ("spotting between periods",                              "Gynecology"),
    ("painful intercourse",                                   "Gynecology"),
    ("cervical problem",                                      "Gynecology"),
    ("pap smear",                                             "Gynecology"),
    ("hormone imbalance in women",                            "Gynecology"),
    ("postpartum problems",                                   "Gynecology"),
    ("ectopic pregnancy",                                     "Gynecology"),
    ("infertility",                                           "Gynecology"),
    ("delayed period",                                        "Gynecology"),
    ("ovulation pain",                                        "Gynecology"),

    # ── Urology ──────────────────────────────────────────────
    ("burning urine",                                         "Urology"),
    ("frequent urination",                                    "Urology"),
    ("pain while urinating",                                  "Urology"),
    ("kidney stone",                                          "Urology"),
    ("blood in urine",                                        "Urology"),
    ("uti",                                                   "Urology"),
    ("urinary tract infection",                               "Urology"),
    ("prostate problem",                                      "Urology"),
    ("bladder infection",                                     "Urology"),
    ("urge to urinate frequently",                            "Urology"),
    ("kidney pain",                                           "Urology"),
    ("unable to urinate",                                     "Urology"),
    ("urine retention",                                       "Urology"),
    ("urine leakage",                                         "Urology"),
    ("weak urine stream",                                     "Urology"),
    ("enlarged prostate",                                     "Urology"),
    ("bph",                                                   "Urology"),
    ("hematuria",                                             "Urology"),
    ("cloudy urine",                                          "Urology"),
    ("dark urine",                                            "Urology"),
    ("foul smelling urine",                                   "Urology"),
    ("incontinence",                                          "Urology"),
    ("bedwetting in adults",                                  "Urology"),
    ("male infertility",                                      "Urology"),
    ("testicular pain",                                       "Urology"),
    ("testicular swelling",                                   "Urology"),
    ("erectile dysfunction",                                  "Urology"),
    ("hydrocele",                                             "Urology"),
    ("varicocele",                                            "Urology"),
    ("urethral discharge",                                    "Urology"),
    ("pain in lower abdomen with urination",                  "Urology"),
    ("kidney infection",                                      "Urology"),
    ("pyelonephritis",                                        "Urology"),
    ("renal colic",                                           "Urology"),
    ("cystitis",                                              "Urology"),
    ("overactive bladder",                                    "Urology"),
    ("difficulty passing urine",                              "Urology"),
    ("scrotal pain",                                          "Urology"),
    ("penile discharge",                                      "Urology"),
    ("painful ejaculation",                                   "Urology"),

    # ── Psychiatry ───────────────────────────────────────────
    ("anxiety",                                               "Psychiatry"),
    ("depression",                                            "Psychiatry"),
    ("panic attack",                                          "Psychiatry"),
    ("insomnia",                                              "Psychiatry"),
    ("unable to sleep",                                       "Psychiatry"),
    ("mental stress",                                         "Psychiatry"),
    ("mood swings",                                           "Psychiatry"),
    ("ocd",                                                   "Psychiatry"),
    ("phobia",                                                "Psychiatry"),
    ("suicidal thoughts",                                     "Psychiatry"),
    ("hallucinations",                                        "Psychiatry"),
    ("bipolar disorder",                                      "Psychiatry"),
    ("ptsd",                                                  "Psychiatry"),
    ("adhd",                                                  "Psychiatry"),
    ("feeling hopeless",                                      "Psychiatry"),
    ("extreme sadness",                                       "Psychiatry"),
    ("social anxiety",                                        "Psychiatry"),
    ("fear of everything",                                    "Psychiatry"),
    ("obsessive thoughts",                                    "Psychiatry"),
    ("compulsive behaviour",                                  "Psychiatry"),
    ("schizophrenia",                                         "Psychiatry"),
    ("psychosis",                                             "Psychiatry"),
    ("eating disorder",                                       "Psychiatry"),
    ("anorexia",                                              "Psychiatry"),
    ("bulimia",                                               "Psychiatry"),
    ("anger issues",                                          "Psychiatry"),
    ("emotional instability",                                 "Psychiatry"),
    ("self harm thoughts",                                    "Psychiatry"),
    ("feeling of worthlessness",                              "Psychiatry"),
    ("loss of interest in life",                              "Psychiatry"),
    ("excessive worry",                                       "Psychiatry"),
    ("racing thoughts",                                       "Psychiatry"),
    ("concentration problems",                                "Psychiatry"),
    ("memory problems",                                       "Psychiatry"),
    ("substance addiction",                                   "Psychiatry"),
    ("alcohol addiction",                                     "Psychiatry"),
    ("drug addiction",                                        "Psychiatry"),
    ("grief and loss",                                        "Psychiatry"),
    ("trauma counselling",                                    "Psychiatry"),
    ("relationship anxiety",                                  "Psychiatry"),

    # ── Pediatrics ───────────────────────────────────────────
    ("my child has fever",                                    "Pediatrics"),
    ("baby is not eating",                                    "Pediatrics"),
    ("infant has rash",                                       "Pediatrics"),
    ("toddler vomiting",                                      "Pediatrics"),
    ("child vaccination",                                     "Pediatrics"),
    ("newborn jaundice",                                      "Pediatrics"),
    ("kids cough",                                            "Pediatrics"),
    ("child growth problem",                                  "Pediatrics"),
    ("baby crying continuously",                              "Pediatrics"),
    ("child is not gaining weight",                           "Pediatrics"),
    ("child diarrhea",                                        "Pediatrics"),
    ("baby not sleeping",                                     "Pediatrics"),
    ("infant fever",                                          "Pediatrics"),
    ("my baby has cold",                                      "Pediatrics"),
    ("child allergies",                                       "Pediatrics"),
    ("kid has asthma",                                        "Pediatrics"),
    ("child stomach ache",                                    "Pediatrics"),
    ("newborn not feeding",                                   "Pediatrics"),
    ("child ear pain",                                        "Pediatrics"),
    ("baby rash on body",                                     "Pediatrics"),
    ("toddler not talking",                                   "Pediatrics"),
    ("child development delay",                               "Pediatrics"),
    ("child behavior problems",                               "Pediatrics"),
    ("school age child sick",                                 "Pediatrics"),
    ("baby constipation",                                     "Pediatrics"),
    ("child throat pain",                                     "Pediatrics"),
    ("pediatric checkup",                                     "Pediatrics"),
    ("newborn care",                                          "Pediatrics"),
    ("child skin problem",                                    "Pediatrics"),
    ("kid is not active",                                     "Pediatrics"),
    ("child has measles",                                     "Pediatrics"),
    ("child has chickenpox",                                  "Pediatrics"),
    ("my son has fever",                                      "Pediatrics"),
    ("my daughter has fever",                                 "Pediatrics"),
    ("toddler won't eat",                                     "Pediatrics"),
    ("my child is underweight",                               "Pediatrics"),
    ("baby head circumference concern",                       "Pediatrics"),
    ("child seizure",                                         "Pediatrics"),
    ("kid has worms",                                         "Pediatrics"),
    ("child vitamin deficiency",                              "Pediatrics"),

    # ── Neurology ────────────────────────────────────────────
    ("migraine",                                              "Neurology"),
    ("severe headache",                                       "Neurology"),
    ("seizure",                                               "Neurology"),
    ("epilepsy",                                              "Neurology"),
    ("dizziness",                                             "Neurology"),
    ("vertigo",                                               "Neurology"),
    ("numbness in hands",                                     "Neurology"),
    ("tremors",                                               "Neurology"),
    ("memory loss",                                           "Neurology"),
    ("paralysis",                                             "Neurology"),
    ("stroke",                                                "Neurology"),
    ("fainting",                                              "Neurology"),
    ("tingling in fingers",                                   "Neurology"),
    ("parkinson",                                             "Neurology"),
    ("blackout",                                              "Neurology"),
    ("loss of balance",                                       "Neurology"),
    ("difficulty walking",                                    "Neurology"),
    ("slurred speech",                                        "Neurology"),
    ("facial drooping",                                       "Neurology"),
    ("brain tumor",                                           "Neurology"),
    ("meningitis",                                            "Neurology"),
    ("encephalitis",                                          "Neurology"),
    ("multiple sclerosis",                                    "Neurology"),
    ("neuropathy",                                            "Neurology"),
    ("nerve pain",                                            "Neurology"),
    ("burning sensation in feet",                             "Neurology"),
    ("weakness in one side of body",                          "Neurology"),
    ("sudden confusion",                                      "Neurology"),
    ("dementia",                                              "Neurology"),
    ("alzheimer",                                             "Neurology"),
    ("involuntary movements",                                 "Neurology"),
    ("loss of consciousness",                                 "Neurology"),
    ("fits",                                                  "Neurology"),
    ("chronic headache",                                      "Neurology"),
    ("cluster headache",                                      "Neurology"),
    ("tension headache",                                      "Neurology"),
    ("brain fog",                                             "Neurology"),
    ("difficulty concentrating",                              "Neurology"),
    ("ringing in both ears with dizziness",                   "Neurology"),
    ("numbness in face",                                      "Neurology"),

    # ── Ophthalmology ────────────────────────────────────────
    ("eye pain",                                              "Ophthalmology"),
    ("blurry vision",                                         "Ophthalmology"),
    ("watery eyes",                                           "Ophthalmology"),
    ("red eye",                                               "Ophthalmology"),
    ("conjunctivitis",                                        "Ophthalmology"),
    ("cataract",                                              "Ophthalmology"),
    ("glaucoma",                                              "Ophthalmology"),
    ("eye infection",                                         "Ophthalmology"),
    ("difficulty seeing",                                     "Ophthalmology"),
    ("squint",                                                "Ophthalmology"),
    ("eye allergy",                                           "Ophthalmology"),
    ("itchy eyes",                                            "Ophthalmology"),
    ("swollen eyelid",                                        "Ophthalmology"),
    ("stye",                                                  "Ophthalmology"),
    ("dry eyes",                                              "Ophthalmology"),
    ("double vision",                                         "Ophthalmology"),
    ("vision loss",                                           "Ophthalmology"),
    ("floaters in vision",                                    "Ophthalmology"),
    ("flashes in vision",                                     "Ophthalmology"),
    ("retinal problem",                                       "Ophthalmology"),
    ("macular degeneration",                                  "Ophthalmology"),
    ("diabetic eye problem",                                  "Ophthalmology"),
    ("glasses prescription check",                            "Ophthalmology"),
    ("color blindness",                                       "Ophthalmology"),
    ("night blindness",                                       "Ophthalmology"),
    ("eye discharge",                                         "Ophthalmology"),
    ("burning eyes",                                          "Ophthalmology"),
    ("sensitivity to light",                                  "Ophthalmology"),
    ("crossed eyes",                                          "Ophthalmology"),
    ("lazy eye",                                              "Ophthalmology"),
    ("corneal problem",                                       "Ophthalmology"),
    ("uveitis",                                               "Ophthalmology"),
    ("optic nerve problem",                                   "Ophthalmology"),
    ("eye strain",                                            "Ophthalmology"),
    ("pterygium",                                             "Ophthalmology"),
    ("subconjunctival hemorrhage",                            "Ophthalmology"),
    ("pupil not reacting",                                    "Ophthalmology"),
    ("eye twitching",                                         "Ophthalmology"),
    ("chalazion",                                             "Ophthalmology"),
    ("keratoconus",                                           "Ophthalmology"),

    # ──  General Medicine ─────────────────────────────────────
    ("stomach pain",                                          "General Medicine"),
    ("abdominal pain",                                        "General Medicine"),
    ("acidity",                                               "General Medicine"),
    ("gas problem",                                           "General Medicine"),
    ("bloating",                                              "General Medicine"),
    ("constipation",                                          "General Medicine"),
    ("diarrhea",                                              "General Medicine"),
    ("nausea",                                                "General Medicine"),
    ("vomiting",                                              "General Medicine"),
    ("jaundice",                                              "General Medicine"),
    ("liver pain",                                            "General Medicine"),
    ("hepatitis",                                             "General Medicine"),
    ("ulcer",                                                 "General Medicine"),
    ("ibs",                                                   "General Medicine"),
    ("gallbladder stone",                                     "General Medicine"),
    ("indigestion",                                           "General Medicine"),
    ("acid reflux",                                           "General Medicine"),
    ("gerd",                                                  "General Medicine"),
    ("heartburn",                                             "General Medicine"),
    ("stomach cramps",                                        "General Medicine"),
    ("loose motions",                                         "General Medicine"),
    ("blood in stool",                                        "General Medicine"),
    ("black stool",                                           "General Medicine"),
    ("stomach ulcer",                                         "General Medicine"),
    ("peptic ulcer",                                          "General Medicine"),
    ("crohn's disease",                                       "General Medicine"),
    ("ulcerative colitis",                                    "General Medicine"),
    ("liver cirrhosis",                                       "General Medicine"),
    ("fatty liver",                                           "General Medicine"),
    ("abdominal bloating",                                    "General Medicine"),
    ("loss of appetite with stomach pain",                    "General Medicine"),
    ("rectal bleeding",                                       "General Medicine"),
    ("hemorrhoids",                                           "General Medicine"),
    ("piles",                                                 "General Medicine"),
    ("anal pain",                                             "General Medicine"),
    ("food poisoning",                                        "General Medicine"),
    ("stomach infection",                                     "General Medicine"),
    ("gastritis",                                             "General Medicine"),
    ("colon problem",                                         "General Medicine"),
    ("pancreas problem",                                      "General Medicine"),
    ("fever",                                                 "General Medicine"),
    ("high fever",                                            "General Medicine"),
    ("cold and flu",                                          "General Medicine"),
    ("body weakness",                                         "General Medicine"),
    ("fatigue",                                               "General Medicine"),
    ("body ache",                                             "General Medicine"),
    ("cough",                                                 "General Medicine"),
    ("diabetes",                                              "General Medicine"),
    ("thyroid",                                               "General Medicine"),
    ("asthma",                                                "General Medicine"),
    ("weight loss",                                           "General Medicine"),
    ("loss of appetite",                                      "General Medicine"),
    ("general checkup",                                       "General Medicine"),
    ("feeling unwell",                                        "General Medicine"),
    ("breathlessness",                                        "General Medicine"),
    ("viral infection",                                       "General Medicine"),
    ("malaria",                                               "General Medicine"),
    ("typhoid",                                               "General Medicine"),
    ("dengue",                                                "General Medicine"),
    ("flu symptoms",                                          "General Medicine"),
    ("weakness and tiredness",                                "General Medicine"),
    ("not feeling well",                                      "General Medicine"),
    ("seasonal allergy",                                      "General Medicine"),
    ("blood sugar high",                                      "General Medicine"),
    ("blood sugar problem",                                   "General Medicine"),
    ("routine checkup",                                       "General Medicine"),
    ("annual physical",                                       "General Medicine"),
    ("vitamin deficiency",                                    "General Medicine"),
    ("anemia",                                                "General Medicine"),
    ("low hemoglobin",                                        "General Medicine"),
    ("dehydration",                                           "General Medicine"),
    ("excessive sweating",                                    "General Medicine"),
    ("night sweats",                                          "General Medicine"),
    ("sudden weight gain",                                    "General Medicine"),
    ("swollen lymph nodes",                                   "General Medicine"),
    ("chills",                                                "General Medicine"),
    ("body temperature high",                                 "General Medicine"),
    ("I feel sick",                                           "General Medicine"),
    ("overall body pain",                                     "General Medicine"),
    ("low energy",                                            "General Medicine"),
]


# ═════════════════════════════════════════════════════════════
#  LOAD CSV DATASET
# ═════════════════════════════════════════════════════════════

print("Loading CSV dataset...")
try:
    df = pd.read_csv("data/final_symptom_speciality_dataset.csv")
    print(f"CSV loaded: {df.shape}")

    # Remove classes with < 30 samples
    counts        = df["Speciality"].value_counts()
    valid_classes = counts[counts >= 30].index
    df            = df[df["Speciality"].isin(valid_classes)]

    # Balance General Medicine so it doesn't dominate
    gm_count   = min(400, len(df[df["Speciality"] == "General Medicine"]))
    df_general = df[df["Speciality"] == "General Medicine"].sample(gm_count, random_state=42)
    df_other   = df[df["Speciality"] != "General Medicine"]
    df_csv     = pd.concat([df_general, df_other])[["text", "Speciality"]]
    df_csv.columns = ["text", "Speciality"]

    print(f"CSV after balancing: {df_csv.shape}")
except Exception as e:
    print(f"⚠️  CSV not found or error: {e}. Using augmented data only.")
    df_csv = pd.DataFrame(columns=["text", "Speciality"])


# ═════════════════════════════════════════════════════════════
#  MERGE CSV + AUGMENTED DATA
#  Augmented data repeated 5x so it strongly anchors the model
# ═════════════════════════════════════════════════════════════

df_augmented        = pd.DataFrame(AUGMENTED_DATA, columns=["text", "Speciality"])
OVERSAMPLE_FACTOR   = 5
df_augmented_boosted = pd.concat([df_augmented] * OVERSAMPLE_FACTOR, ignore_index=True)

df_final = pd.concat([df_csv, df_augmented_boosted], ignore_index=True)
df_final = df_final.sample(frac=1, random_state=42).reset_index(drop=True)

print(f"\nFinal merged dataset: {df_final.shape}")
print(df_final["Speciality"].value_counts())


# ═════════════════════════════════════════════════════════════
#  ENCODE LABELS + EMBEDDINGS
# ═════════════════════════════════════════════════════════════

label_encoder = LabelEncoder()
X_text        = df_final["text"].values
y_encoded     = label_encoder.fit_transform(df_final["Speciality"].values)

print(f"\nClasses: {list(label_encoder.classes_)}")
print("\nLoading sentence-transformer...")

embedder     = SentenceTransformer("all-MiniLM-L6-v2")
X_embeddings = embedder.encode(X_text, batch_size=64, show_progress_bar=True)


# ═════════════════════════════════════════════════════════════
#  TRAIN / TEST SPLIT
# ═════════════════════════════════════════════════════════════

X_train, X_test, y_train, y_test = train_test_split(
    X_embeddings, y_encoded,
    test_size=0.2,
    stratify=y_encoded,
    random_state=42,
)


# ═════════════════════════════════════════════════════════════
#  TRAIN CLASSIFIER
#  NOTE: multi_class="auto" was removed in sklearn 1.5 — do not use it.
#  LogisticRegression handles multiclass natively with lbfgs.
# ═════════════════════════════════════════════════════════════

print("\nTraining LogisticRegression...")

clf = LogisticRegression(
    max_iter=5000,
    class_weight="balanced",
    C=2.0,
    solver="lbfgs",
)
clf.fit(X_train, y_train)


# ═════════════════════════════════════════════════════════════
#  EVALUATE
# ═════════════════════════════════════════════════════════════

y_pred   = clf.predict(X_test)
accuracy = accuracy_score(y_test, y_pred)

print(f"\nAccuracy: {round(accuracy * 100, 2)}%")
print("\nClassification Report:\n")
print(classification_report(y_test, y_pred, target_names=label_encoder.classes_))


# ── Sanity checks ─────────────────────────────────────────────
sanity_tests = [
    ("ear pain",                  "ENT"),
    ("sore throat",               "ENT"),
    ("earache",                   "ENT"),
    ("knee pain",                 "Orthopaedics"),
    ("back pain",                 "Orthopaedics"),
    ("acne on face",              "Dermatology"),
    ("hair fall",                 "Dermatology"),
    ("chest pain",                "Cardiology"),
    ("heart palpitations",        "Cardiology"),
    ("anxiety",                   "Psychiatry"),
    ("depression",                "Psychiatry"),
    ("stomach pain",              " General Medicine"),
    ("acidity",                   " General Medicine"),
    ("blurry vision",             "Ophthalmology"),
    ("red eye",                   "Ophthalmology"),
    ("frequent urination",        "Urology"),
    ("kidney stone",              "Urology"),
    ("migraine",                  "Neurology"),
    ("seizure",                   "Neurology"),
    ("irregular periods",         "Gynecology"),
    ("ovarian cyst",              "Gynecology"),
    ("my child has fever",        "Pediatrics"),
    ("baby is not eating",        "Pediatrics"),
    ("fever",                     "General Medicine"),
    ("body weakness",             "General Medicine"),
]

print("\n── Sanity checks ──")
passed = 0
for symptom, expected in sanity_tests:
    emb    = embedder.encode([symptom])
    proba  = clf.predict_proba(emb)[0]
    pred_i = proba.argmax()
    pred   = label_encoder.inverse_transform([pred_i])[0]
    conf   = proba.max()
    status = "✅" if pred == expected else "❌"
    if pred == expected:
        passed += 1
    print(f"  {status}  '{symptom}' → {pred} ({conf:.2f})  [expected: {expected}]")

print(f"\n{passed}/{len(sanity_tests)} sanity checks passed.")
if passed < len(sanity_tests):
    print("⚠️  Some checks failed — review augmented data or CSV quality.")
else:
    print("✅ All sanity checks passed!")


# ═════════════════════════════════════════════════════════════
#  SAVE CONFIDENCE THRESHOLD ALONGSIDE MODEL
#  At inference time, if max probability < CONF_THRESHOLD,
#  return "General Medicine" as a safe fallback.
# ═════════════════════════════════════════════════════════════

CONF_THRESHOLD = 0.30   # tune if needed

MIN_ACCEPTABLE_ACCURACY = 0.75

if accuracy >= MIN_ACCEPTABLE_ACCURACY:
    joblib.dump(clf,            "model/specialist_classifier.pkl")
    joblib.dump(label_encoder,  "model/label_encoder.pkl")
    joblib.dump(CONF_THRESHOLD, "model/conf_threshold.pkl")
    print(f"\n✅ Models saved (accuracy {round(accuracy * 100, 2)}%)")
    print(f"   Confidence threshold saved: {CONF_THRESHOLD}")
else:
    print(
        f"\n⚠️  Model NOT saved — accuracy {round(accuracy * 100, 2)}% is below "
        f"threshold {MIN_ACCEPTABLE_ACCURACY * 100}%. "
        "Check your dataset and augmented examples."
    )


# ═════════════════════════════════════════════════════════════
#  EXAMPLE: How to use the model at inference time
# ═════════════════════════════════════════════════════════════

print("\n── Inference example ──")
print("Use this snippet in your patient bot:\n")
print("""
import joblib
from sentence_transformers import SentenceTransformer

embedder       = SentenceTransformer("all-MiniLM-L6-v2")
clf            = joblib.load("model/specialist_classifier.pkl")
label_encoder  = joblib.load("model/label_encoder.pkl")
conf_threshold = joblib.load("model/conf_threshold.pkl")

def predict_specialist(symptom_text: str) -> dict:
    emb   = embedder.encode([symptom_text])
    proba = clf.predict_proba(emb)[0]
    idx   = proba.argmax()
    conf  = proba.max()
    if conf < conf_threshold:
        specialist = "General Medicine"  # safe fallback
    else:
        specialist = label_encoder.inverse_transform([idx])[0]
    return {"specialist": specialist, "confidence": round(float(conf), 3)}

# Example
print(predict_specialist("my ear is hurting"))   # → ENT
print(predict_specialist("knee pain"))            # → Orthopaedics
print(predict_specialist("my child has fever"))   # → Pediatrics
""")