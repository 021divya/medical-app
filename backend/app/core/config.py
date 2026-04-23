import os

class Settings:
    PROJECT_NAME: str = "Swasthya Chatbot"
    PROJECT_VERSION: str = "1.0.0"
    
    # SECURITY WARNING: Change this in production!
    SECRET_KEY: str = "09d25e094faa6ca2556c818166b7a9563b93f7099f6f0f4caa6cf63b88e8d3e7"
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 30
    
    # Database (Using SQLite for easy testing, change to PostgreSQL for production)
    DATABASE_URL: str = "sqlite:///./sql_app.db"

settings = Settings()