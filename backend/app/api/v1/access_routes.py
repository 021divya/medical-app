from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from datetime import datetime
from typing import List
from app.core.database import get_db
from app.api.deps import get_current_user
from app.models.user import User
from app.models.access_request import AccessRequest
from app.models.medical import MedicalRecord
from app.schemas.access_request import AccessRequestCreate, AccessRequestOut

router = APIRouter()


# ─────────────────────────────────────────────────────────────────
#  DOCTOR: Send access request to a patient
#  POST /api/v1/access/request
# ─────────────────────────────────────────────────────────────────
@router.post("/request", response_model=AccessRequestOut)
def send_access_request(
    body: AccessRequestCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    if current_user.role != "doctor":
        raise HTTPException(status_code=403, detail="Only doctors can send access requests")

    # Check patient exists
    patient = db.query(User).filter(User.id == body.patient_id, User.role == "patient").first()
    if not patient:
        raise HTTPException(status_code=404, detail="Patient not found")

    # Check if request already exists
    existing = db.query(AccessRequest).filter(
        AccessRequest.doctor_id == current_user.id,
        AccessRequest.patient_id == body.patient_id,
        AccessRequest.status == "pending",
    ).first()
    if existing:
        raise HTTPException(status_code=400, detail="Request already pending")

    req = AccessRequest(
        doctor_id=current_user.id,
        patient_id=body.patient_id,
    )
    db.add(req)
    db.commit()
    db.refresh(req)

    return _enrich(req, db)


# ─────────────────────────────────────────────────────────────────
#  PATIENT: Get all incoming access requests
#  GET /api/v1/access/my-requests
# ─────────────────────────────────────────────────────────────────
@router.get("/my-requests", response_model=List[AccessRequestOut])
def get_my_requests(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    if current_user.role != "patient":
        raise HTTPException(status_code=403, detail="Only patients can view their requests")

    requests = db.query(AccessRequest).filter(
        AccessRequest.patient_id == current_user.id
    ).order_by(AccessRequest.created_at.desc()).all()

    return [_enrich(r, db) for r in requests]


# ─────────────────────────────────────────────────────────────────
#  PATIENT: Approve or reject a request
#  POST /api/v1/access/respond/{request_id}
# ─────────────────────────────────────────────────────────────────
@router.post("/respond/{request_id}", response_model=AccessRequestOut)
def respond_to_request(
    request_id: int,
    action: str,  # "approved" or "rejected"
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    if current_user.role != "patient":
        raise HTTPException(status_code=403, detail="Only patients can respond")

    if action not in ("approved", "rejected"):
        raise HTTPException(status_code=400, detail="action must be 'approved' or 'rejected'")

    req = db.query(AccessRequest).filter(
        AccessRequest.id == request_id,
        AccessRequest.patient_id == current_user.id,
    ).first()

    if not req:
        raise HTTPException(status_code=404, detail="Request not found")

    req.status = action
    req.responded_at = datetime.utcnow()
    db.commit()
    db.refresh(req)

    return _enrich(req, db)


# ─────────────────────────────────────────────────────────────────
#  DOCTOR: Get list of patients who approved me
#  GET /api/v1/access/approved-patients
# ─────────────────────────────────────────────────────────────────
@router.get("/approved-patients")
def get_approved_patients(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    if current_user.role != "doctor":
        raise HTTPException(status_code=403, detail="Only doctors can use this")

    approved = db.query(AccessRequest).filter(
        AccessRequest.doctor_id == current_user.id,
        AccessRequest.status == "approved",
    ).all()

    result = []
    for req in approved:
        patient = db.query(User).filter(User.id == req.patient_id).first()
        if patient:
            result.append({
                "patient_id": patient.id,
                "patient_name": patient.full_name,
                "patient_email": patient.email,
                "approved_at": req.responded_at,
            })
    return result


# ─────────────────────────────────────────────────────────────────
#  DOCTOR: Get records of an approved patient
#  GET /api/v1/access/patient-records/{patient_id}
# ─────────────────────────────────────────────────────────────────
@router.get("/patient-records/{patient_id}")
def get_patient_records(
    patient_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    if current_user.role != "doctor":
        raise HTTPException(status_code=403, detail="Only doctors can use this")

    # Check doctor has approved access
    approved = db.query(AccessRequest).filter(
        AccessRequest.doctor_id == current_user.id,
        AccessRequest.patient_id == patient_id,
        AccessRequest.status == "approved",
    ).first()

    if not approved:
        raise HTTPException(
            status_code=403,
            detail="Access not approved by this patient"
        )

    records = db.query(MedicalRecord).filter(
        MedicalRecord.user_id == patient_id
    ).all()

    return records


# ─────────────────────────────────────────────────────────────────
#  DOCTOR: Check status of my request to a specific patient
#  GET /api/v1/access/status/{patient_id}
# ─────────────────────────────────────────────────────────────────
@router.get("/status/{patient_id}")
def get_request_status(
    patient_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    if current_user.role != "doctor":
        raise HTTPException(status_code=403, detail="Only doctors can use this")

    req = db.query(AccessRequest).filter(
        AccessRequest.doctor_id == current_user.id,
        AccessRequest.patient_id == patient_id,
    ).order_by(AccessRequest.created_at.desc()).first()

    if not req:
        return {"status": "not_requested"}

    return {"status": req.status, "request_id": req.id}


# ─────────────────────────────────────────────────────────────────
#  PATIENT: Notification count (pending requests)
#  GET /api/v1/access/notification-count
# ─────────────────────────────────────────────────────────────────
@router.get("/notification-count")
def get_notification_count(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    count = db.query(AccessRequest).filter(
        AccessRequest.patient_id == current_user.id,
        AccessRequest.status == "pending",
    ).count()
    return {"count": count}


# ─────────────────────────────────────────────────────────────────
#  Helper: Add doctor/patient names to response
# ─────────────────────────────────────────────────────────────────
def _enrich(req: AccessRequest, db: Session) -> dict:
    doctor = db.query(User).filter(User.id == req.doctor_id).first()
    patient = db.query(User).filter(User.id == req.patient_id).first()
    return {
        "id": req.id,
        "doctor_id": req.doctor_id,
        "patient_id": req.patient_id,
        "status": req.status,
        "created_at": req.created_at,
        "responded_at": req.responded_at,
        "doctor_name": doctor.full_name if doctor else None,
        "doctor_email": doctor.email if doctor else None,
        "patient_name": patient.full_name if patient else None,
        "patient_email": patient.email if patient else None,
    }

@router.post("/verify-doctor")
def verify_doctor(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    if current_user.role != "doctor":
        raise HTTPException(status_code=403, detail="Only doctors")
    current_user.is_verified = True
    db.commit()
    return {"message": "Doctor verified!"}
