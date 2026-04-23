from fastapi import APIRouter, Depends, UploadFile, File, Form, HTTPException
from sqlalchemy.orm import Session
import shutil
import os
from typing import List
from app.core import database
from app.models import medical, user
from app.schemas import medical as schemas
from app.api import deps

router = APIRouter()

# Create a folder called "uploads" to store the files
UPLOAD_DIR = "uploads"
if not os.path.exists(UPLOAD_DIR):
    os.makedirs(UPLOAD_DIR)

@router.post("/", response_model=schemas.RecordOut)
async def upload_medical_record(
    title: str = Form(...),
    description: str = Form(None),
    file: UploadFile = File(...),
    db: Session = Depends(database.get_db),
    current_user: user.User = Depends(deps.get_current_user)
):
    # 1. Create a unique file path
    file_location = f"{UPLOAD_DIR}/{current_user.id}_{file.filename}"
    
    # 2. Save the file to your computer
    with open(file_location, "wb") as buffer:
        shutil.copyfileobj(file.file, buffer)
    
    # 3. Save the details to the Database
    new_record = medical.MedicalRecord(
        title=title,
        description=description,
        file_url=file_location,
        user_id=current_user.id
    )
    
    db.add(new_record)
    db.commit()
    db.refresh(new_record)
    
    return new_record

@router.get("/", response_model=List[schemas.RecordOut])
def get_my_records(
    db: Session = Depends(database.get_db),
    current_user: user.User = Depends(deps.get_current_user)
):
    # Show only the logged-in user's records
    return db.query(medical.MedicalRecord).filter(medical.MedicalRecord.user_id == current_user.id).all()