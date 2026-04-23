from pydantic import BaseModel
from datetime import datetime


# ── Medical Record ────────────────────────────────────────────────
class RecordCreate(BaseModel):
    title: str
    description: str | None = None


class RecordOut(RecordCreate):
    id:         int
    file_url:   str
    created_at: datetime
    user_id:    int

    class Config:
        from_attributes = True


# ── Prescription ──────────────────────────────────────────────────
class PrescriptionOut(BaseModel):
    id:           int
    patient_id:   int
    doctor_id:    int
    title:        str
    notes:        str | None
    file_url:     str | None
    created_at:   datetime
    doctor_name:  str | None = None   # enriched in route
    patient_name: str | None = None   # enriched in route

    class Config:
        from_attributes = True