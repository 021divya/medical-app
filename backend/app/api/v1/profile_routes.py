from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from app.core.database import get_db
from app.api.deps import get_current_user
from app.models.user import User
from pydantic import BaseModel

router = APIRouter()

class ProfileUpdate(BaseModel):
    name: str | None = None
    email: str | None = None
    phone: str | None = None
    gender: str | None = None
    dob: str | None = None
    blood_group: str | None = None
    marital_status: str | None = None
    height: str | None = None
    weight: str | None = None
    emergency_contact: str | None = None

    allergies: str | None = None
    medications: str | None = None
    past_medications: str | None = None
    chronic_diseases: str | None = None
    injuries: str | None = None
    surgeries: str | None = None

    smoking: str | None = None
    alcohol: str | None = None
    activity_level: str | None = None
    food_preference: str | None = None
    occupation: str | None = None




@router.put("/update-profile")
def update_profile(
    data: ProfileUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    user = db.query(User).filter(User.id == current_user.id).first()

    for key, value in data.dict(exclude_unset=True).items():
        
        # 🔥 HANDLE NAME MISMATCH
        if key == "name":
            user.full_name = value

        # 🔥 SAFE UPDATE ONLY IF FIELD EXISTS
        elif hasattr(user, key):
            setattr(user, key, value)

    db.commit()
    db.refresh(user)

    return {
        "message": "Profile updated successfully",
        "user": {
            "name": user.full_name,
            "phone": user.phone,
            "gender": user.gender,
            "weight": user.weight,
        }
    }
"""""
@router.put("/update-profile")
def update_profile(
    data: ProfileUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    user = db.query(User).filter(User.id == current_user.id).first()

    for key, value in data.dict(exclude_unset=True).items():
        setattr(user, key, value)

    db.commit()
    db.refresh(user)

    return {"message": "Profile updated successfully"}
    """