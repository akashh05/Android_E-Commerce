from typing import Optional
from pydantic import BaseModel, EmailStr, Field

# 📌 User Models
class User(BaseModel):
    email: EmailStr
    password: str
    role: str = Field(default="customer", pattern="^(admin|customer)$")

class UserLogin(BaseModel):
    email: EmailStr
    password: str

class ForgotPasswordRequest(BaseModel):
    email: EmailStr

class OTPVerifyRequest(BaseModel):
    email: EmailStr
    otp: str
    new_password: str  # ✅ Added for OTP-based password reset

# 🛒 Item Model
class Item(BaseModel):
    name: str
    price: float
    description: Optional[str] = None
    image_url: Optional[str] = None  # ✅ Field to store image URL
