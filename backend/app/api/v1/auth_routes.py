from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.security import OAuth2PasswordRequestForm
from sqlalchemy.orm import Session
from app.core import security, database
from app.core.config import settings
from app.models.user import User
from app.schemas.user import UserCreate, UserOut, Token
from app.api.deps import get_current_user
from datetime import timedelta
from datetime import datetime
from fastapi import Form
from app.core.email import send_otp_email

router = APIRouter()


@router.post("/signup")
def create_user(user: UserCreate, db: Session = Depends(database.get_db)):
    db_user = db.query(User).filter(User.email == user.email).first()
    if db_user:
        raise HTTPException(status_code=400, detail="Email already registered")

    hashed_password = security.get_password_hash(user.password)
    new_user = User(
        email=user.email,
        full_name=user.full_name,
        role=user.role,
        hashed_password=hashed_password,
    )
    db.add(new_user)
    db.commit()
    db.refresh(new_user)
    return new_user


@router.post("/login", response_model=Token)
def login(
    form_data: OAuth2PasswordRequestForm = Depends(),
    db: Session = Depends(database.get_db),
):
    user = db.query(User).filter(User.email == form_data.username).first()
    if not user or not security.verify_password(form_data.password, user.hashed_password):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect email or password",
        )
    access_token = security.create_access_token(
        data={"sub": user.email},
        expires_delta=timedelta(minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES),
    )
    return {"access_token": access_token, "token_type": "bearer"}

@router.post("/forgot-password")
def forgot_password(email: str = Form(...), db: Session = Depends(database.get_db)):
    
    user = db.query(User).filter(User.email == email).first()

    if not user:
        raise HTTPException(status_code=404, detail="User not found")

    # generate OTP
    otp = security.generate_otp()
    expiry = security.get_otp_expiry()
    send_otp_email(email, otp)

    # save OTP in database
    user.otp = otp
    user.otp_expiry = expiry

    db.commit()

    # for now we return OTP (later we will send email)
    return {
    "message": "OTP sent to your email"
}
    

@router.post("/verify-otp")
def verify_otp(email: str = Form(...), otp: str = Form(...), db: Session = Depends(database.get_db)):
    user = db.query(User).filter(User.email == email).first()

    if not user:
        raise HTTPException(status_code=404, detail="User not found")

    if user.otp != otp:
        raise HTTPException(status_code=400, detail="Invalid OTP")

    if user.otp_expiry is None or user.otp_expiry < datetime.utcnow():
        raise HTTPException(status_code=400, detail="OTP expired")

    return {"message": "OTP verified successfully"}

@router.post("/reset-password")
def reset_password(email: str = Form(...), new_password: str = Form(...), db: Session = Depends(database.get_db)):
    user = db.query(User).filter(User.email == email).first()

    if not user:
        raise HTTPException(status_code=404, detail="User not found")

    hashed_password = security.get_password_hash(new_password)

    user.hashed_password = hashed_password
    user.otp = None
    user.otp_expiry = None

    db.commit()

    return {"message": "Password reset successful"}


@router.get("/me")
def read_users_me(current_user: User = Depends(get_current_user)):
    return {
        "id": current_user.id,
        "email": current_user.email,
        "role": current_user.role,
        "full_name": current_user.full_name,
        "is_verified": current_user.is_verified,  # ✅ NAYA
    }

