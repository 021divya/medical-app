from fastapi import APIRouter
from database.db import cursor

router = APIRouter()

@router.get("/patient_history/{patient_id}")
def get_patient_history(patient_id: str):

    cursor.execute(
        "SELECT report_date, summary FROM patient_reports WHERE patient_id=? ORDER BY report_date",
        (patient_id,)
    )

    reports = cursor.fetchall()

    timeline = []

    for date, summary in reports:
        timeline.append(f"{date} → {summary}")

    return {
        "patient_id": patient_id,
        "timeline": timeline
    }