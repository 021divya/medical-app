# ============================================================
# PATH: app/api/v1/appointment_routes.py
# ============================================================

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from datetime import datetime
from typing import List

from app.core.database import get_db
from app.api.deps import get_current_user
from app.models.user import User
from app.models.appointment import Appointment
from app.schemas.appointment import AppointmentCreate, AppointmentOut, AppointmentCancelOut

router = APIRouter()


# ─────────────────────────────────────────────────────────────────
#  POST /api/v1/appointments/book
# ─────────────────────────────────────────────────────────────────
@router.post("/book", response_model=AppointmentOut)
def book_appointment(
    body: AppointmentCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    if current_user.role != "patient":
        raise HTTPException(status_code=403, detail="Only patients can book appointments")

    existing = db.query(Appointment).filter(
        Appointment.booking_id == body.booking_id
    ).first()
    if existing:
        raise HTTPException(status_code=400, detail="Booking ID already exists")

    slot_taken = db.query(Appointment).filter(
        Appointment.doctor_name      == body.doctor_name,
        Appointment.appointment_date == body.appointment_date,
        Appointment.appointment_slot == body.appointment_slot,
        Appointment.status           != "cancelled",
    ).first()
    if slot_taken:
        raise HTTPException(
            status_code=409,
            detail="This slot is already booked. Please choose another time."
        )

    appt = Appointment(
        patient_id        = current_user.id,
        doctor_name       = body.doctor_name,
        doctor_reg_no     = body.doctor_reg_no,
        doctor_speciality = body.doctor_speciality,
        appointment_date  = body.appointment_date,
        appointment_slot  = body.appointment_slot,
        visit_type        = body.visit_type,
        patient_name      = body.patient_name,
        patient_phone     = body.patient_phone,
        reason            = body.reason,
        amount_paid       = body.amount_paid,
        payment_method    = body.payment_method,
        booking_id        = body.booking_id,
        payment_status    = "paid",
        status            = "confirmed",
    )

    db.add(appt)
    db.commit()
    db.refresh(appt)
    return appt


# ─────────────────────────────────────────────────────────────────
#  GET /api/v1/appointments/my
# ─────────────────────────────────────────────────────────────────
@router.get("/my", response_model=List[AppointmentOut])
def get_my_appointments(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    if current_user.role != "patient":
        raise HTTPException(status_code=403, detail="Only patients can view appointments")

    return (
        db.query(Appointment)
        .filter(Appointment.patient_id == current_user.id)
        .order_by(Appointment.created_at.desc())
        .all()
    )


# ─────────────────────────────────────────────────────────────────
#  GET /api/v1/appointments/upcoming
# ─────────────────────────────────────────────────────────────────
@router.get("/upcoming", response_model=List[AppointmentOut])
def get_upcoming_appointments(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    today = datetime.utcnow().strftime("%Y-%m-%d")

    return (
        db.query(Appointment)
        .filter(
            Appointment.patient_id       == current_user.id,
            Appointment.status           == "confirmed",
            Appointment.appointment_date >= today,
        )
        .order_by(Appointment.appointment_date.asc())
        .all()
    )


# ─────────────────────────────────────────────────────────────────
#  GET /api/v1/appointments/slots/{doctor_name}/{date}
# ─────────────────────────────────────────────────────────────────
@router.get("/slots/{doctor_name}/{date}")
def get_booked_slots(
    doctor_name: str,
    date: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    booked = (
        db.query(Appointment.appointment_slot)
        .filter(
            Appointment.doctor_name      == doctor_name,
            Appointment.appointment_date == date,
            Appointment.status           != "cancelled",
        )
        .all()
    )
    return {"booked_slots": [row[0] for row in booked]}


# ─────────────────────────────────────────────────────────────────
#  DELETE /api/v1/appointments/{appointment_id}
# ─────────────────────────────────────────────────────────────────
@router.delete("/{appointment_id}", response_model=AppointmentCancelOut)
def cancel_appointment(
    appointment_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    appt = db.query(Appointment).filter(
        Appointment.id         == appointment_id,
        Appointment.patient_id == current_user.id,
    ).first()

    if not appt:
        raise HTTPException(status_code=404, detail="Appointment not found")

    if appt.status == "cancelled":
        raise HTTPException(status_code=400, detail="Already cancelled")

    appt.status       = "cancelled"
    appt.cancelled_at = datetime.utcnow()
    db.commit()
    db.refresh(appt)

    return AppointmentCancelOut(
        message      = "Appointment cancelled successfully",
        booking_id   = appt.booking_id,
        cancelled_at = appt.cancelled_at,
    )


# ─────────────────────────────────────────────────────────────────
#  GET /api/v1/appointments/{appointment_id}
# ─────────────────────────────────────────────────────────────────
@router.get("/{appointment_id}", response_model=AppointmentOut)
def get_appointment_detail(
    appointment_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    appt = db.query(Appointment).filter(
        Appointment.id         == appointment_id,
        Appointment.patient_id == current_user.id,
    ).first()

    if not appt:
        raise HTTPException(status_code=404, detail="Appointment not found")

    return appt