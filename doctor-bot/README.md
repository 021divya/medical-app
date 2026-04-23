Doctor AI Bot 🩺

Doctor AI Bot is the backend service for the Doctor Dashboard in the AI Medical Assistant Application.

It helps doctors quickly analyze patient medical reports and view summarized medical histories using AI.

Features

Upload and analyze medical reports (PDF, Image, DOCX)

Extract medical parameters from reports

Detect abnormal lab values

Generate AI-based report summaries

Maintain patient medical history timeline

Doctor chatbot for medical queries

Project Structure
doctor-bot
│
├── main.py
│
├── routes
│   ├── upload_report.py
│   └── patient_history.py
│
├── services
│   ├── document_extractor.py
│   ├── report_parser.py
│   ├── abnormal_detector.py
│   └── ai_summary.py
│
├── database
│   └── db.py
│
├── requirements.txt
└── README.md

System Architecture

Patient uploads medical report

        ↓

AI Processing Pipeline

- Document extraction (PDF / Image / DOCX)
- Parameter extraction
- Abnormal value detection
- AI summary generation

        ↓

Database Storage

- Patient reports
- AI summaries
- Medical history

        ↓

Doctor Dashboard

- Latest report analysis
- Patient history timeline
- Doctor AI assistant


API Endpoints
Upload Medical Report

POST /upload_report

Uploads a patient medical report and performs AI analysis.

Parameters:

patient_id – Unique patient identifier

file – Medical report (PDF, JPG, PNG, DOCX)

Example Response:

{
 "parameters": {
   "hemoglobin": 9.8,
   "cholesterol": 245
 },
 "abnormal_values": {
   "hemoglobin": "LOW",
   "cholesterol": "HIGH"
 },
 "summary": "Hemoglobin low, Cholesterol high"
}
Get Patient History

GET /patient_history/{patient_id}

Returns the patient's medical timeline summary.

Example Response:

{
 "patient_id": "P101",
 "timeline": [
   "2023 → Cholesterol high",
   "2024 → Vitamin D deficiency",
   "2025 → Hemoglobin low"
 ]
}
Installation

Clone the repository

git clone https://github.com/021divya/doctor-ai-bot.git

Navigate into the project folder

cd doctor-ai-bot

Create a virtual environment

python -m venv venv

Activate virtual environment

Windows:

venv\Scripts\activate

Install dependencies

pip install -r requirements.txt

Run the server

uvicorn main:app --reload
API Documentation

Once the server starts, open:

http://127.0.0.1:8000/docs

This provides the Swagger UI to test all endpoints.

Technologies Used

Python

FastAPI

SQLite

OCR (Tesseract)

NLP / AI summarization