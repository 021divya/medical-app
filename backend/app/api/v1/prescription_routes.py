from fastapi import APIRouter, Depends, UploadFile, File, Form, HTTPException
from sqlalchemy.orm import Session
from typing import List, Optional
import shutil
import os

from app.core.database import get_db
from app.api.deps import get_current_user
from app.models.user import User
from app.models.access_request import AccessRequest
from app.models.medical import Prescription

router = APIRouter()

UPLOAD_DIR = "uploads"
os.makedirs(UPLOAD_DIR, exist_ok=True)


def _assert_approved(doctor_id: int, patient_id: int, db: Session):
    approved = db.query(AccessRequest).filter(
        AccessRequest.doctor_id  == doctor_id,
        AccessRequest.patient_id == patient_id,
        AccessRequest.status     == "approved",
    ).first()
    if not approved:
        raise HTTPException(
            status_code=403,
            detail="Access not approved by this patient",
        )


def _enrich(p: Prescription, db: Session) -> dict:
    doctor  = db.query(User).filter(User.id == p.doctor_id).first()
    patient = db.query(User).filter(User.id == p.patient_id).first()
    return {
        "id":           p.id,
        "patient_id":   p.patient_id,
        "doctor_id":    p.doctor_id,
        "title":        p.title,
        "notes":        p.notes,
        "file_url":     p.file_url,
        "created_at":   p.created_at,
        "doctor_name":  doctor.full_name  if doctor  else None,
        "patient_name": patient.full_name if patient else None,
    }


# ── POST /api/v1/prescriptions/  ← Flutter calls this
@router.post("/")
async def upload_prescription(
    patient_id: int                  = Form(...),
    title:      str                  = Form(...),
    notes:      Optional[str]        = Form(None),
    file:       Optional[UploadFile] = File(None),
    db:         Session              = Depends(get_db),
    current_user: User               = Depends(get_current_user),
):
    if current_user.role != "doctor":
        raise HTTPException(status_code=403, detail="Only doctors can upload prescriptions")

    patient = db.query(User).filter(User.id == patient_id, User.role == "patient").first()
    if not patient:
        raise HTTPException(status_code=404, detail="Patient not found")

    _assert_approved(current_user.id, patient_id, db)

    file_url: Optional[str] = None
    if file and file.filename:
        file_location = f"{UPLOAD_DIR}/prescription_{current_user.id}_{patient_id}_{file.filename}"
        with open(file_location, "wb") as buffer:
            shutil.copyfileobj(file.file, buffer)
        file_url = file_location

    prescription = Prescription(
        patient_id=patient_id,
        doctor_id=current_user.id,
        title=title,
        notes=notes,
        file_url=file_url,
    )
    db.add(prescription)
    db.commit()
    db.refresh(prescription)

    return _enrich(prescription, db)


# ── GET /api/v1/prescriptions/patient/{patient_id}  ← Flutter calls this
@router.get("/patient/{patient_id}")
def get_prescriptions_for_patient(
    patient_id:   int,
    db:           Session = Depends(get_db),
    current_user: User    = Depends(get_current_user),
):
    if current_user.role == "doctor":
        _assert_approved(current_user.id, patient_id, db)
        prescriptions = db.query(Prescription).filter(
            Prescription.patient_id == patient_id,
            Prescription.doctor_id  == current_user.id,
        ).order_by(Prescription.created_at.desc()).all()

    elif current_user.role == "patient":
        if current_user.id != patient_id:
            raise HTTPException(status_code=403, detail="Access denied")
        prescriptions = db.query(Prescription).filter(
            Prescription.patient_id == patient_id,
        ).order_by(Prescription.created_at.desc()).all()

    else:
        raise HTTPException(status_code=403, detail="Access denied")

    return [_enrich(p, db) for p in prescriptions]


# ── GET /api/v1/prescriptions/my-prescriptions  ← patient view
@router.get("/my-prescriptions")
def get_my_prescriptions(
    db:           Session = Depends(get_db),
    current_user: User    = Depends(get_current_user),
):
    if current_user.role != "patient":
        raise HTTPException(status_code=403, detail="Only patients can use this")

    prescriptions = db.query(Prescription).filter(
        Prescription.patient_id == current_user.id,
    ).order_by(Prescription.created_at.desc()).all()

    return [_enrich(p, db) for p in prescriptions]


# ── Keep old routes so nothing else breaks ──────────────────────

@router.post("/upload")
async def upload_prescription_legacy(
    patient_id: int                  = Form(...),
    title:      str                  = Form(...),
    notes:      Optional[str]        = Form(None),
    file:       Optional[UploadFile] = File(None),
    db:         Session              = Depends(get_db),
    current_user: User               = Depends(get_current_user),
):
    return await upload_prescription(
        patient_id=patient_id, title=title, notes=notes,
        file=file, db=db, current_user=current_user,
    )


@router.get("/for-patient/{patient_id}")
def get_prescriptions_legacy(
    patient_id:   int,
    db:           Session = Depends(get_db),
    current_user: User    = Depends(get_current_user),
):
    return get_prescriptions_for_patient(
        patient_id=patient_id, db=db, current_user=current_user,
    )