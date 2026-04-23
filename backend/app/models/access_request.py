from sqlalchemy import Column, Integer, String, ForeignKey, DateTime
from sqlalchemy.orm import relationship
from datetime import datetime
from app.core.database import Base


class AccessRequest(Base):
    __tablename__ = "access_requests"

    id = Column(Integer, primary_key=True, index=True)

    # Doctor who is requesting access
    doctor_id = Column(Integer, ForeignKey("users.id"), nullable=False)

    # Patient whose records the doctor wants to see
    patient_id = Column(Integer, ForeignKey("users.id"), nullable=False)

    # "pending", "approved", "rejected"
    status = Column(String, default="pending")

    # When request was made
    created_at = Column(DateTime, default=datetime.utcnow)

    # When patient responded
    responded_at = Column(DateTime, nullable=True)

    # Relationships
    doctor = relationship("User", foreign_keys=[doctor_id])
    patient = relationship("User", foreign_keys=[patient_id])
