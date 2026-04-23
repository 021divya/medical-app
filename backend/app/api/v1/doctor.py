from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from typing import List
from app.core import database
from app.models import medical, user
from app.schemas import medical as schemas
from app.api import deps

router = APIRouter()

# Helper: Check if the user is actually a Doctor
def check_doctor_role(current_user: user.User = Depends(deps.get_current_user)):
    if current_user.role != "doctor":
        raise HTTPException(status_code=403, detail="Not authorized. Doctors only.")
    return current_user

# 1. Get ALL Medical Records (from ALL patients)
@router.get("/all-records", response_model=List[schemas.RecordOut])
def get_all_patient_records(
    db: Session = Depends(database.get_db),
    current_user: user.User = Depends(check_doctor_role) # <--- Security Check
):
    # Retrieve every single record in the database
    return db.query(medical.MedicalRecord).all()

# 2. Get List of All Patients
@router.get("/patients")
def get_all_patients(
    db: Session = Depends(database.get_db),
    current_user: user.User = Depends(check_doctor_role)
):
    # Get all users who are patients
    patients = db.query(user.User).filter(user.User.role == "patient").all()
    return [{"id": p.id, "name": p.full_name, "email": p.email} for p in patients]