from sqlalchemy import Column, Integer, String, Boolean, DateTime
from sqlalchemy.orm import relationship
from app.core.database import Base
from datetime import datetime

class User(Base):
    __tablename__ = "users"

    id              = Column(Integer, primary_key=True, index=True)
    email           = Column(String, unique=True, index=True)
    hashed_password = Column(String)
    full_name       = Column(String)
    role            = Column(String)  # "doctor", "patient", "admin"
    is_active       = Column(Boolean, default=True)
    is_verified     = Column(Boolean, default=False)

    # 🔹 PASSWORD RESET
    otp        = Column(String, nullable=True)
    otp_expiry = Column(DateTime, nullable=True)

    # 🔥 PERSONAL
    phone             = Column(String, nullable=True)
    gender            = Column(String, nullable=True)
    dob               = Column(String, nullable=True)
    blood_group       = Column(String, nullable=True)
    marital_status    = Column(String, nullable=True)
    height            = Column(String, nullable=True)
    weight            = Column(String, nullable=True)
    emergency_contact = Column(String, nullable=True)

    # 🔥 MEDICAL
    allergies        = Column(String, nullable=True)
    medications      = Column(String, nullable=True)
    past_medications = Column(String, nullable=True)
    chronic_diseases = Column(String, nullable=True)
    injuries         = Column(String, nullable=True)
    surgeries        = Column(String, nullable=True)

    # 🔥 LIFESTYLE
    smoking         = Column(String, nullable=True)
    alcohol         = Column(String, nullable=True)
    activity_level  = Column(String, nullable=True)
    food_preference = Column(String, nullable=True)
    occupation      = Column(String, nullable=True)

    # ── Relationships ─────────────────────────────────────────────
    chat_sessions   = relationship("ChatSession",   back_populates="user")
    medical_records = relationship("MedicalRecord", back_populates="patient")

    # 🔹 PRESCRIPTION relationships
    prescriptions        = relationship("Prescription", foreign_keys="[Prescription.patient_id]", back_populates="patient")
    issued_prescriptions = relationship("Prescription", foreign_keys="[Prescription.doctor_id]",  back_populates="doctor")

    # 🔹 APPOINTMENT relationships
    appointments = relationship("Appointment", foreign_keys="[Appointment.patient_id]", back_populates="patient")