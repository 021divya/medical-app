from pydantic import BaseModel
from datetime import datetime
from typing import Optional


class AccessRequestCreate(BaseModel):
    patient_id: int


class AccessRequestOut(BaseModel):
    id: int
    doctor_id: int
    patient_id: int
    status: str
    created_at: datetime
    responded_at: Optional[datetime] = None

    doctor_name: Optional[str] = None
    doctor_email: Optional[str] = None

    patient_name: Optional[str] = None
    patient_email: Optional[str] = None

    class Config:
        from_attributes = True



