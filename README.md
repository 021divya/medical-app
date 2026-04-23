# 🩺 AI Medical Assistant App

## 📘 Introduction

The AI Medical Assistant App is an intelligent healthcare solution that uses artificial intelligence to provide faster, smarter, and more accessible medical support. It helps patients analyze symptoms, understand medical reports, and find suitable doctors, while also assisting healthcare professionals with data insights and management.

---

## 📌 Project Modules

### 1. Main Backend

Handles core logic, APIs, and data management.

### 2. Doctor AI Bot

* Analyzes medical reports (PDF/Image/DOCX)
* Extracts parameters
* Detects abnormal values
* Generates AI-based summaries

### 3. Patient Triage Bot

* Takes symptoms as input
* Predicts specialist using ML
* Recommends doctors

### 4. Flutter Frontend

* User interface for patients and doctors
* Connects all backend services

---

## 🏗️ Tech Stack

**Frontend**

* Flutter (Android Studio)

**Backend**

* FastAPI
* Python
* SQLite

**AI / ML**

* Scikit-learn
* Sentence Transformers
* Hugging Face Transformers

**Other**

* Firebase (Auth & Storage)

## 📂 Project Structure


ai-medical-app/
│
├── frontend/          
├── main-backend/      
├── doctor-bot/        
└── patient-bot/   

## ⚙️ Backend Setup (Repeat for all 3 backends)

cd folder_name
python -m venv venv
venv\Scripts\activate
pip install -r requirements.txt

## ▶️ Run Backends

Run each service on different ports:

* Main Backend → 8000
* Doctor Bot → 8001
* Patient Bot → 8002

## 🌐 API Testing

Open in browser:

* http://127.0.0.1:8000/docs
* http://127.0.0.1:8001/docs
* http://127.0.0.1:8002/docs

## 📱 Frontend Setup

cd frontend
flutter pub get

### Update API URLs (for emulator)

http://10.0.2.2:8000
http://10.0.2.2:8001
http://10.0.2.2:8002

## ▶️ Run App

*Main Backend → python -m uvicorn app.main:app --reload --port 8000 --host 0.0.0.0
*Doctor Bot →   python -m uvicorn main:app --reload --port 8001 --host 0.0.0.0
*Patient Bot → python -m uvicorn api:app --reload --port 8002 --host 0.0.0.0
*frontend →flutter clean
           flutter pub get
           flutter run

## 🔄 App Workflow

**Patient**

* Enter symptoms → Get specialist → View doctor recommendations

**Doctor**

* Upload report → AI analysis → View summary & history

## 📦 Features

✔ Symptom-based specialist prediction
✔ Doctor recommendation system
✔ Medical report analysis & summarization
✔ Patient history tracking
✔ AI-powered chatbot


## ❗ Common Issues

**CORS Error**

* Enable CORS in FastAPI

**API not working in emulator**

Use 10.0.2.2 instead of 127.0.0.1

**Missing packages**

pip install <package-name>

## 🚀 Future Improvements

* Cloud deployment
* Better ML models
* Real-time doctor chat
* Improved UI/UX

## 👩‍💻 Author

AI-based healthcare assistant project using Flutter and FastAPI.

---
