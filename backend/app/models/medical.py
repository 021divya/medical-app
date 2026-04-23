from sqlalchemy import Column, Integer, String, ForeignKey, DateTime, Text
from sqlalchemy.orm import relationship
from datetime import datetime
from app.core.database import Base
from pydantic import BaseModel
from typing import Optional


# ══════════════════════════════════════════════════════════════
#  ORM MODELS
# ══════════════════════════════════════════════════════════════

class MedicalRecord(Base):
    __tablename__ = "medical_records"

    id          = Column(Integer, primary_key=True, index=True)
    user_id     = Column(Integer, ForeignKey("users.id"))   # Patient who owns the record
    title       = Column(String)
    description = Column(Text)
    file_url    = Column(String)
    created_at  = Column(DateTime, default=datetime.utcnow)

    patient = relationship("User", back_populates="medical_records")


class Prescription(Base):
    __tablename__ = "prescriptions"

    id         = Column(Integer, primary_key=True, index=True)
    patient_id = Column(Integer, ForeignKey("users.id"))   # Patient this is for
    doctor_id  = Column(Integer, ForeignKey("users.id"))   # Doctor who uploaded it
    title      = Column(String)                            # e.g. "Post-visit prescription"
    notes      = Column(Text, nullable=True)               # Optional doctor notes
    file_url   = Column(String, nullable=True)             # Attached file (optional)
    created_at = Column(DateTime, default=datetime.utcnow)

    patient = relationship("User", foreign_keys=[patient_id], back_populates="prescriptions")
    doctor  = relationship("User", foreign_keys=[doctor_id],  back_populates="issued_prescriptions")


# ══════════════════════════════════════════════════════════════
#  PYDANTIC SCHEMAS
# ══════════════════════════════════════════════════════════════

# ── Medical Record ────────────────────────────────────────────────
class RecordCreate(BaseModel):
    title: str
    description: Optional[str] = None


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
    notes:        Optional[str]
    file_url:     Optional[str]
    created_at:   datetime
    doctor_name:  Optional[str] = None   # enriched in route
    patient_name: Optional[str] = None   # enriched in route

    class Config:
        from_attributes = True