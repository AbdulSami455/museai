from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles

from app.api import router
from app.config import get_settings
from app.services.storage import ensure_local_storage_dir

settings = get_settings()
app = FastAPI(title=settings.project_name, version="0.1.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(router, prefix=settings.api_prefix)

if not settings.firebase_storage_bucket:
    assets_dir = ensure_local_storage_dir()
    app.mount("/assets", StaticFiles(directory=assets_dir), name="assets")
