from functools import lru_cache

import firebase_admin
from firebase_admin import auth, credentials, firestore, storage

from app.config import get_settings


@lru_cache
def get_firebase_app() -> firebase_admin.App:
    settings = get_settings()
    if firebase_admin._apps:
        return firebase_admin.get_app()

    options: dict[str, str] = {}
    if settings.firebase_project_id:
        options["projectId"] = settings.firebase_project_id
    if settings.firebase_storage_bucket:
        options["storageBucket"] = settings.firebase_storage_bucket

    if settings.google_application_credentials:
        cred = credentials.Certificate(settings.google_application_credentials)
        return firebase_admin.initialize_app(cred, options=options)

    return firebase_admin.initialize_app(options=options)


def get_firestore_client() -> firestore.Client:
    get_firebase_app()
    return firestore.client()


def get_auth_module():
    get_firebase_app()
    return auth


def get_storage_bucket():
    get_firebase_app()
    return storage.bucket()
