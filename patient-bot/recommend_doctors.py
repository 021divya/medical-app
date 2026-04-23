import pandas as pd
from predict_specialist import predict_specialist
from distance_utils import get_distance_km

# =========================
# Load cleaned dataset
# =========================
doctor_df = pd.read_csv("data/clean_doctor_dataset.csv")

doctor_df.columns = (
    doctor_df.columns
    .str.strip()
    .str.lower()
    .str.replace(" ", "_")
)

doctor_df["area"]      = doctor_df["area"].astype(str).str.lower().str.strip()
doctor_df["speciality"] = doctor_df["speciality"].astype(str).str.lower().str.strip()

# =========================
# ✅ Speciality mapping — only dataset values
# =========================
SPECIALITY_MAP = {
    "general medicine": ["general medicine"],
    "neurology":        ["neurology"],
    "cardiology":       ["cardiology"],
    "dermatology":      ["dermatology"],
    "ent":              ["ent"],
    "orthopaedics":     ["orthopaedics", "orthopaedics "],  # trailing space in dataset
    "gynecology":       ["gynecology"],
    "urology":          ["urology"],
    "psychiatry":       ["psychiatry"],
    "pediatrics":       ["pediatrics"],
}

def recommend_doctors(
    symptoms_text=None,
    specialist=None,
    patient_lat=None,
    patient_lng=None,
    location_text=None,
    max_distance_km=5,
    max_fees=2000,
    min_rating=4.0
):
    # ------------------------------------
    # Determine specialist
    # ------------------------------------
    if specialist is None:
        specialist = predict_specialist(symptoms_text)

    if isinstance(specialist, tuple):
        specialist = specialist[0]

    specialist = str(specialist).lower().strip()

    # ------------------------------------
    # Match to dataset speciality
    # ------------------------------------
    allowed_specialities = SPECIALITY_MAP.get(specialist, [specialist])

    df_specialist = doctor_df[
        doctor_df["speciality"].str.strip().isin(allowed_specialities)
    ].copy()

    if df_specialist.empty:
        # Try partial match as fallback
        df_specialist = doctor_df[
            doctor_df["speciality"].str.contains(specialist, case=False, na=False)
        ].copy()

    if df_specialist.empty:
        return pd.DataFrame()

    # ------------------------------------
    # Locality filtering
    # ------------------------------------
    if location_text is None:
        df_base = df_specialist
        locality_used = False
    else:
        user_area = location_text.lower().split(",")[0].strip()
        locality_df = df_specialist[
            df_specialist["area"].str.startswith(user_area)
        ].copy()

        if not locality_df.empty:
            df_base = locality_df
            locality_used = True
        else:
            df_base = df_specialist
            locality_used = False

    # ------------------------------------
    # Distance calculation
    # ------------------------------------
    if patient_lat is not None and patient_lng is not None:
        df_base["distance_km"] = df_base.apply(
            lambda row: get_distance_km(
                patient_lat, patient_lng,
                row["latitude"], row["longitude"]
            ),
            axis=1
        )
    else:
        df_base["distance_km"] = 999

    # ------------------------------------
    # Filter + sort
    # ------------------------------------
    DISTANCE_LEVELS = [3, 5, 10, 20]

    for radius in DISTANCE_LEVELS:
        if radius < max_distance_km:
            continue

        df = df_base[
            (df_base["distance_km"] <= radius) &
            (df_base["fees"] <= max_fees) &
            (df_base["rating"] >= min_rating)
        ].copy()

        if not df.empty:
            df["used_radius_km"] = radius
            df["match_type"] = "locality" if locality_used else "distance"
            return df.sort_values(
                by=["rating", "distance_km"],
                ascending=[False, True]
            )

    return pd.DataFrame()