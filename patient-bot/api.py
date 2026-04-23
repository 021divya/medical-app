
# ============================================================
#  api.py  —  AI Patient Bot  (FastAPI Server)
#  Run:  uvicorn api:app --host 0.0.0.0 --port 8002 --reload
# ============================================================

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel

from bot_flow          import handle_message, reset_session, get_all_sessions  # ← added debug
from recommend_doctors import recommend_doctors
from geocode_utils     import geocode_location
import os
import logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)
logger.info("🚀 Starting API server...")
app = FastAPI(title="AI Medical Assistant Bot", version="4.1")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

# ─────────────────────────────────────────────────────────────
# Request Models
# ─────────────────────────────────────────────────────────────

class SymptomRequest(BaseModel):
    symptoms: str
    user_id:  str = "guest"

class RecommendRequest(BaseModel):
    specialist:      str
    location_text:   str   = ""
    user_id:         str   = "guest"
    max_distance_km: float = 10.0
    max_fees:        int   = 5000
    min_rating:      float = 0.0

class ResetRequest(BaseModel):
    user_id: str = "guest"

# ─────────────────────────────────────────────────────────────
# Routes
# ─────────────────────────────────────────────────────────────

@app.get("/health")
def health_check():
    return {"status": "ok", "message": "AI Patient Bot is running!"}


@app.get("/debug/sessions")
def debug_sessions():
    """

    Open in browser: http://127.0.0.1:8002/debug/sessions
    Shows ALL active sessions and their current stage.
    Use this to catch stale sessions causing the bug.
    """

    return get_all_sessions()


@app.post("/reset")
def reset_user_session(data: ResetRequest):
    """
    Called by Flutter whenever the user starts a new chat.
    Wipes the server-side session so the next message is treated
    as a fresh symptom input — not a mid-flow continuation.
    """

    reset_session(data.user_id)
    return {"status": "ok", "message": "Session reset."}


@app.post("/symptoms")
def process_symptoms(data: SymptomRequest):
    return handle_message(data.symptoms, user_id=data.user_id)


@app.post("/recommend")
def recommend(data: RecommendRequest):
    import logging
    log = logging.getLogger("api")

    # Safety net: log exactly what Flutter sent — helps debug empty specialist
    log.debug(
        f"[RECOMMEND] specialist='{data.specialist}' "
        f"location='{data.location_text}' "
        f"dist={data.max_distance_km} fees={data.max_fees} rating={data.min_rating}"
    )

    if not data.specialist:
        log.warning("[RECOMMEND] specialist is EMPTY — Flutter sent blank specialist!")

    lat, lng = geocode_location(data.location_text)

    results = recommend_doctors(
        specialist      = data.specialist,
        patient_lat     = lat,
        patient_lng     = lng,
        location_text   = data.location_text,
        max_distance_km = data.max_distance_km,
        max_fees        = data.max_fees,
        min_rating      = data.min_rating,
    )

    if results.empty:
        return {
            "message": f"I recommend {data.specialist}, but no doctors found nearby.",
            "doctors": []
        }

    doctors = results.to_dict(orient="records")
    return {
        "message": f"Here are doctors near {data.location_text} for {data.specialist}:",
        "doctors": doctors,
    }
    
if __name__ == "__main__":
    import uvicorn
    uvicorn.run("api:app", host="0.0.0.0", port=int(os.environ.get("PORT", 10000)))