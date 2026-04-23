from fastapi import APIRouter, UploadFile, File, HTTPException
from services.document_extractor import extract_text
from services.report_parser import extract_parameters
from services.abnormal_detector import detect_abnormal
from services.ai_summary import generate_summary
from database.db import cursor, conn
from datetime import datetime

router = APIRouter()

@router.post("/upload_report")
async def upload_report(patient_id: str, file: UploadFile = File(...)):

    try:

        text = extract_text(file)

        parameters = extract_parameters(text)

        abnormal = detect_abnormal(parameters)

        summary = generate_summary(parameters, abnormal)

        # Save report in database
        cursor.execute(
            "INSERT INTO patient_reports (patient_id, report_date, summary) VALUES (?, ?, ?)",
            (patient_id, datetime.now().strftime("%Y-%m-%d"), summary)
        )

        conn.commit()

        return {
            "filename": file.filename,
            "parameters": parameters,
            "abnormal_values": abnormal,
            "summary": summary
        }

    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))