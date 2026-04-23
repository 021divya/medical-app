import sqlite3

conn = sqlite3.connect("medical_reports.db", check_same_thread=False)
cursor = conn.cursor()

cursor.execute("""
CREATE TABLE IF NOT EXISTS patient_reports (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    patient_id TEXT,
    report_date TEXT,
    summary TEXT
)
""")

conn.commit()