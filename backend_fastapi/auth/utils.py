import bcrypt
from jose import jwt
from datetime import datetime, timedelta
import random
import smtplib
from email.message import EmailMessage
from config import (
    JWT_SECRET,
    JWT_ALGORITHM,
    EMAIL_FROM,
    EMAIL_PASSWORD,
    SMTP_SERVER,
    SMTP_PORT,
)

# 🔐 Hash a password
def hash_password(password: str) -> str:
    return bcrypt.hashpw(password.encode(), bcrypt.gensalt()).decode()

# 🔐 Verify a password against its hash
def verify_password(password: str, hashed: str) -> bool:
    return bcrypt.checkpw(password.encode(), hashed.encode())

# 🔑 Create JWT access token
def create_access_token(email: str, role: str) -> str:
    expire = datetime.utcnow() + timedelta(hours=2)
    payload = {
        "sub": email,
        "role": role,
        "exp": expire,
    }
    return jwt.encode(payload, JWT_SECRET, algorithm=JWT_ALGORITHM)

# 📧 Send an email (reusable)
def send_email(to_email: str, subject: str, body: str):
    msg = EmailMessage()
    msg["Subject"] = subject
    msg["From"] = EMAIL_FROM
    msg["To"] = to_email
    msg.set_content(body)

    try:
        with smtplib.SMTP(SMTP_SERVER, SMTP_PORT) as server:
            server.starttls()
            server.login(EMAIL_FROM, EMAIL_PASSWORD)
            server.send_message(msg)
        print(f"[✅] Email sent to {to_email}")
    except Exception as e:
        print(f"[❌] Email sending failed to {to_email}: {e}")

# 🔐 In-memory OTP store (use database in production)
otp_store = {}

# 🔢 Generate OTP and send only OTP email (no link)
def generate_otp(email: str) -> str:
    otp = str(random.randint(100000, 999999))
    otp_store[email] = {
        "otp": otp,
        "expires": datetime.utcnow() + timedelta(minutes=10),
    }

    subject = "Your OTP Code"
    body = f"Your OTP for password reset is: {otp}. It is valid for 10 minutes."
    send_email(email, subject, body)

    return otp

# ✅ Verify OTP
def verify_otp(email: str, otp: str) -> bool:
    entry = otp_store.get(email)
    if not entry:
        return False
    if entry["otp"] != otp:
        return False
    if datetime.utcnow() > entry["expires"]:
        return False
    return True
