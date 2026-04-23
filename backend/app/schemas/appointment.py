# PATH: app/schemas/appointment.py

from pydantic import BaseModel
from datetime import datetime
from typing import Optional


class AppointmentCreate(BaseModel):
    doctor_name:       str
    doctor_reg_no:     Optional[str] = None
    doctor_speciality: Optional[str] = None
    appointment_date:  str
    appointment_slot:  str
    visit_type:        str
    patient_name:      str
    patient_phone:     str
    reason:            Optional[str] = None
    amount_paid:       int
    payment_method:    str
    booking_id:        str


class AppointmentOut(BaseModel):
    id:                int
    patient_id:        int
    doctor_name:       str
    doctor_reg_no:     Optional[str] = None
    doctor_speciality: Optional[str] = None
    appointment_date:  str
    appointment_slot:  str
    visit_type:        str
    patient_name:      str
    patient_phone:     str
    reason:            Optional[str] = None
    amount_paid:       int
    payment_method:    str
    booking_id:        str
    payment_status:    str
    status:            str
    created_at:        datetime
    cancelled_at:      Optional[datetime] = None

    class Config:
        from_attributes = True


class AppointmentCancelOut(BaseModel):
    message:      str
    booking_id:   str
    cancelled_at: datetime