"""Local file storage service (replaces S3 in dev mode)."""
import os
import uuid
from datetime import date

from app.config import get_settings

settings = get_settings()


def save_photo(user_id: str, photo_date: date, photo_type: str, file_bytes: bytes, suffix: str = ".jpg") -> str:
    """Save a photo to local storage. Returns the relative URL path."""
    filename = f"{user_id}_{photo_date.isoformat()}_{photo_type}_{uuid.uuid4().hex[:8]}{suffix}"
    filepath = os.path.join(settings.local_storage_path, filename)
    with open(filepath, "wb") as f:
        f.write(file_bytes)
    return f"/uploads/{filename}"


def save_thumbnail(file_bytes: bytes) -> str:
    """Save a thumbnail to local storage."""
    filename = f"thumb_{uuid.uuid4().hex[:12]}.jpg"
    filepath = os.path.join(settings.local_storage_path, filename)
    with open(filepath, "wb") as f:
        f.write(file_bytes)
    return f"/uploads/{filename}"
