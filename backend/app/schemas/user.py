from pydantic import BaseModel
from typing import Optional

# Base Schema
class UserBase(BaseModel):
    email: str
    full_name: str | None = None
    role: str = "patient" # default to patient

# Schema for creating a user (Signup)
class UserCreate(UserBase):
    password: str

# Schema for reading user data (Response)
class UserOut(UserBase):
    id: int
    is_active: bool
    class Config:
        from_attributes = True

# Token Schemas
class Token(BaseModel):
    access_token: str
    token_type: str

class TokenData(BaseModel):
    email: str | None = None