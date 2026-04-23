from dotenv import load_dotenv
load_dotenv()  # ← MUST be first, before any os.getenv() calls
import os


from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from app.core.database import engine, Base
from app.api.v1 import (
    auth_routes,
    chat,
    records,
    doctor,
    access_routes,
    admin_routes,
    profile_routes,
    appointment_routes,
    prescription_routes,
)
from app.models import access_request
from app.models import appointment as appointment_model
from app.models.medical import Prescription
from app.api.health_content_routes import router as health_router
from pydantic import BaseModel
import razorpay
import hmac
import hashlib
import os

app = FastAPI(title="Swasthya / Medico AI Backend")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=False,
    allow_methods=["*"],
    allow_headers=["*"],
)

Base.metadata.create_all(bind=engine)
UPLOAD_DIR = "uploads"
os.makedirs(UPLOAD_DIR, exist_ok=True)
app.mount("/uploads", StaticFiles(directory=UPLOAD_DIR), name="uploads")

app.include_router(auth_routes.router,         prefix="/api/v1/auth",          tags=["Auth"])
app.include_router(chat.router,                prefix="/api/v1/chat",          tags=["Chat"])
app.include_router(records.router,             prefix="/api/v1/records",       tags=["Medical Records"])
app.include_router(doctor.router,              prefix="/api/v1/doctor",        tags=["Doctor Dashboard"])
app.include_router(access_routes.router,       prefix="/api/v1/access",        tags=["Access Requests"])
app.include_router(admin_routes.router,        prefix="/api/v1/admin",         tags=["Admin"])
app.include_router(health_router,              prefix="/api/v1")
app.include_router(profile_routes.router,      prefix="/api/v1/profile",       tags=["Profile"])
app.include_router(appointment_routes.router,  prefix="/api/v1/appointments",  tags=["Appointments"])
app.include_router(prescription_routes.router, prefix="/api/v1/prescriptions", tags=["Prescriptions"])


# ── Razorpay credentials (loaded from .env) ───────────────────────────────
RAZORPAY_KEY_ID     = os.getenv("RAZORPAY_KEY_ID")
RAZORPAY_KEY_SECRET = os.getenv("RAZORPAY_KEY_SECRET")


# ── Payment schemas ───────────────────────────────────────────────────────
class OrderRequest(BaseModel):
    amount: int  # paise

class VerifyRequest(BaseModel):
    razorpay_order_id: str
    razorpay_payment_id: str
    razorpay_signature: str


# ── Payment routes ────────────────────────────────────────────────────────
@app.post("/api/v1/payment/create_order", tags=["Payment"])
def create_order(req: OrderRequest):
    if not RAZORPAY_KEY_ID or not RAZORPAY_KEY_SECRET:
        raise HTTPException(
            status_code=500,
            detail="Razorpay keys not configured. Check your .env file."
        )
    try:
        client = razorpay.Client(auth=(RAZORPAY_KEY_ID, RAZORPAY_KEY_SECRET))
        order = client.order.create({
            "amount": req.amount,
            "currency": "INR",
            "payment_capture": 1,
        })
        return order
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Razorpay order creation failed: {e}")


@app.post("/api/v1/payment/verify", tags=["Payment"])
def verify_payment(req: VerifyRequest):
    if not RAZORPAY_KEY_SECRET:
        raise HTTPException(status_code=500, detail="Razorpay secret not configured.")
    try:
        body = f"{req.razorpay_order_id}|{req.razorpay_payment_id}"
        expected = hmac.new(
            RAZORPAY_KEY_SECRET.encode("utf-8"),
            body.encode("utf-8"),
            hashlib.sha256,
        ).hexdigest()
        if expected == req.razorpay_signature:
            return {"status": "ok", "verified": True}
        raise HTTPException(status_code=400, detail="Invalid payment signature")
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Verification error: {e}")


@app.get("/")
def read_root():
    return {"message": "Medico AI Backend is running ✅"}
