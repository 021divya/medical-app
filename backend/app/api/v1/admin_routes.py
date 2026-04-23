from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from app.core.database import get_db
from app.models.user import User
from app.models.medical import MedicalRecord
from app.models.access_request import AccessRequest

router = APIRouter()

@router.get("/stats")
def get_admin_stats(db: Session = Depends(get_db)):
    total_doctors = db.query(User).filter(User.role == "doctor").count()
    total_patients = db.query(User).filter(User.role == "patient").count()
    total_requests = db.query(AccessRequest).count()

    doctors = db.query(User).filter(User.role == "doctor").order_by(User.id.desc()).all()
    patients = db.query(User).filter(User.role == "patient").order_by(User.id.desc()).all()
    requests = db.query(AccessRequest).order_by(AccessRequest.id.desc()).all()

    recent_doctors = [
        {"id": d.id, "full_name": d.full_name, "email": d.email, "is_verified": d.is_verified}
        for d in doctors
    ]

    recent_patients = []
    for p in patients:
        record_count = db.query(MedicalRecord).filter(MedicalRecord.user_id == p.id).count()
        recent_patients.append({
            "id": p.id, "full_name": p.full_name,
            "email": p.email, "record_count": record_count,
        })

    all_requests = [
        {"id": r.id, "doctor_id": r.doctor_id, "patient_id": r.patient_id, "status": r.status}
        for r in requests
    ]

    return {
        "total_doctors": total_doctors,
        "total_patients": total_patients,
        "total_requests": total_requests,
        "recent_doctors": recent_doctors,
        "recent_patients": recent_patients,
        "all_requests": all_requests,
    }