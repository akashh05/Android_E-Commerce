import os
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from pymongo import MongoClient

from auth.routes import router as auth_router
from auth.utils import hash_password
from config import MONGO_URI

# 🔗 Connect to MongoDB
client = MongoClient(MONGO_URI)
db = client["authdb"]
users = db["users"]

# 🚀 Instantiate FastAPI app
app = FastAPI(
    title="E-Commerce Backend",
    description="FastAPI + MongoDB backend for user auth and item management",
    version="1.0.0"
)

# 🌐 Enable CORS (adjust allow_origins/allow_methods in production)
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],       # e.g., ["https://your-frontend.com"]
    allow_credentials=True,
    allow_methods=["*"],       # e.g., ["GET", "POST", "PUT", "DELETE"]
    allow_headers=["*"],
)

# 📁 Serve uploaded images from /uploads URL path
UPLOADS_DIR = "/home/ec2-user/Android_E-Commerce/backend_fastapi/uploads"
os.makedirs(UPLOADS_DIR, exist_ok=True)
app.mount("/uploads", StaticFiles(directory=UPLOADS_DIR), name="uploads")

# 👤 Create initial admin on startup
@app.on_event("startup")
def create_initial_admin():
    admin_email = "admin123@gmail.com"
    admin_plain = "Admin@123"
    if not users.find_one({"email": admin_email}):
        users.insert_one({
            "email": admin_email,
            "password": hash_password(admin_plain),
            "role": "admin"
        })
        print(f"🔥 Created initial admin user: {admin_email}")

# 📦 Include all auth & item routes
app.include_router(auth_router)

# 🏃‍♂️ Run via `uvicorn main:app --reload --host 0.0.0.0 --port 8000`
if __name__ == "__main__":
    import uvicorn
    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=True)
