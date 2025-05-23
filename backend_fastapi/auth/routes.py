import os
import uuid
import shutil
from fastapi import (
    APIRouter,
    HTTPException,
    status,
    Depends,
    Header,
    Path,
    UploadFile,
    File,
    Request,
)
from jose import JWTError, jwt
from pymongo import MongoClient
from bson import ObjectId
from pydantic import BaseModel

from auth.models import (
    User,
    UserLogin,
    ForgotPasswordRequest,
    OTPVerifyRequest,
    Item,
)
from auth.utils import (
    hash_password,
    verify_password,
    create_access_token,
    generate_otp,
    verify_otp,
)
from config import JWT_SECRET, JWT_ALGORITHM

router = APIRouter()

# ─── MongoDB setup ─────────────────────────────────────────────────────────────
client = MongoClient("mongodb://localhost:27017")
db = client["authdb"]
users_collection = db["users"]
items_collection = db["items"]

# ─── Auth dependency ────────────────────────────────────────────────────────────
def get_current_user(authorization: str = Header(...)):
    if not authorization.startswith("Bearer "):
        raise HTTPException(status_code=401, detail="Invalid authorization header")
    token = authorization.split(" ")[1]
    try:
        payload = jwt.decode(token, JWT_SECRET, algorithms=[JWT_ALGORITHM])
        email = payload.get("sub")
        role = payload.get("role", "customer")
        if email is None:
            raise HTTPException(status_code=401, detail="Invalid token payload")
        return {"email": email, "role": role}
    except JWTError:
        raise HTTPException(status_code=401, detail="Invalid or expired token")

# ─── Signup ─────────────────────────────────────────────────────────────────────
@router.post("/signup", status_code=status.HTTP_201_CREATED)
async def signup(data: User):
    if users_collection.find_one({"email": data.email}):
        raise HTTPException(status_code=400, detail="Email already registered")
    hashed = hash_password(data.password)
    users_collection.insert_one({
        "email": data.email,
        "password": hashed,
        "role": data.role,
    })
    return {"msg": "User registered successfully"}

# ─── Login ──────────────────────────────────────────────────────────────────────
@router.post("/login")
async def login(data: UserLogin):
    user = users_collection.find_one({"email": data.email})
    if not user or not verify_password(data.password, user["password"]):
        raise HTTPException(status_code=401, detail="Invalid credentials")
    token = create_access_token(data.email, user.get("role", "customer"))
    return {"access_token": token, "token_type": "bearer"}

# ─── Request OTP for Password Reset ─────────────────────────────────────────────
@router.post("/request-reset-otp")
async def request_reset_otp(data: ForgotPasswordRequest):
    user = users_collection.find_one({"email": data.email})
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    generate_otp(data.email)
    return {"msg": "OTP sent to your email"}

# ─── Reset Password Using OTP ───────────────────────────────────────────────────
@router.post("/reset-password-otp")
async def reset_password_otp(data: OTPVerifyRequest):
    # Verify OTP
    if not verify_otp(data.email, data.otp):
        raise HTTPException(status_code=400, detail="Invalid or expired OTP")
    # Ensure new password is provided
    if not data.new_password:
        raise HTTPException(status_code=400, detail="Missing new password")
    # Hash and update
    hashed = hash_password(data.new_password)
    result = users_collection.update_one(
        {"email": data.email},
        {"$set": {"password": hashed}}
    )
    if result.modified_count == 0:
        raise HTTPException(status_code=500, detail="Password update failed")
    return {"msg": "Password reset successfully"}

# ─── Add Item (Authenticated) ──────────────────────────────────────────────────
@router.post("/items", status_code=status.HTTP_201_CREATED)
def add_item(item: Item, user=Depends(get_current_user)):
    item_doc = item.dict()
    item_doc["owner"] = user["email"]
    res = items_collection.insert_one(item_doc)
    item_doc["_id"] = str(res.inserted_id)
    return {"msg": "Item added successfully", "item": item_doc}

# ─── List Items ────────────────────────────────────────────────────────────────
@router.get("/items")
def get_items(user=Depends(get_current_user)):
    raw = items_collection.find({"owner": user["email"]})
    out = []
    for doc in raw:
        doc["_id"] = str(doc["_id"])
        out.append(doc)
    return {"items": out}

# ─── Delete Item ───────────────────────────────────────────────────────────────
@router.delete("/items/{item_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_item(
    item_id: str = Path(..., description="The ID of the item to delete"),
    user=Depends(get_current_user),
):
    if not ObjectId.is_valid(item_id):
        raise HTTPException(status_code=400, detail="Invalid item ID")
    result = items_collection.delete_one({
        "_id": ObjectId(item_id),
        "owner": user["email"]
    })
    if result.deleted_count == 0:
        raise HTTPException(status_code=404, detail="Item not found or unauthorized")
    return

# ─── Upload Image ───────────────────────────────────────────────────────────────
@router.post("/upload-image")
async def upload_image(request: Request, file: UploadFile = File(...)):
    filename = f"{uuid.uuid4().hex}_{file.filename}"
    upload_dir = os.path.join(os.getcwd(), "uploads")
    os.makedirs(upload_dir, exist_ok=True)
    path = os.path.join(upload_dir, filename)
    with open(path, "wb") as buf:
        shutil.copyfileobj(file.file, buf)

    host = request.client.host or request.url.hostname
    port = request.url.port or 8000
    image_url = f"http://13.60.32.137:8000/uploads/{filename}"
    return {"image_url": image_url}
