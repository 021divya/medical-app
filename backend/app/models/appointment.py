from sqlalchemy import Column, Integer, String, ForeignKey, DateTime
from sqlalchemy.orm import relationship
from datetime import datetime
from app.core.database import Base


class Appointment(Base):
    __tablename__ = "appointments"

    id             = Column(Integer, primary_key=True, index=True)
    patient_id     = Column(Integer, ForeignKey("users.id"), nullable=False)
    doctor_name    = Column(String, nullable=False)
    doctor_reg_no  = Column(String, nullable=True)
    doctor_speciality = Column(String, nullable=True)
    appointment_date  = Column(String, nullable=False)
    appointment_slot  = Column(String, nullable=False)
    visit_type        = Column(String, nullable=False)
    patient_name   = Column(String, nullable=False)
    patient_phone  = Column(String, nullable=False)
    reason         = Column(String, nullable=True)
    amount_paid    = Column(Integer, nullable=False)
    payment_method = Column(String, nullable=False)
    booking_id     = Column(String, unique=True, nullable=False)
    payment_status = Column(String, default="paid")
    status         = Column(String, default="confirmed")
    created_at     = Column(DateTime, default=datetime.utcnow)
    cancelled_at   = Column(DateTime, nullable=True)

    patient = relationship("User", foreign_keys=[patient_id])