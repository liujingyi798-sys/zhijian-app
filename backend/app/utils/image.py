"""Image processing utilities."""
import io
from PIL import Image


def create_thumbnail(image_bytes: bytes, size: tuple[int, int] = (300, 300)) -> bytes:
    """Create a square thumbnail from image bytes."""
    img = Image.open(io.BytesIO(image_bytes))
    img = img.convert("RGB")

    # Center crop to square
    w, h = img.size
    s = min(w, h)
    left = (w - s) // 2
    top = (h - s) // 2
    img = img.crop((left, top, left + s, top + s))

    img = img.resize(size, Image.LANCZOS)

    buf = io.BytesIO()
    img.save(buf, format="JPEG", quality=80)
    return buf.getvalue()


def validate_photo(image_bytes: bytes, max_size_mb: int = 20) -> tuple[bool, str]:
    """Validate uploaded photo. Returns (is_valid, error_message)."""
    if len(image_bytes) > max_size_mb * 1024 * 1024:
        return False, f"照片大小超过 {max_size_mb}MB 限制"

    try:
        img = Image.open(io.BytesIO(image_bytes))
        img.verify()
        if img.format not in ("JPEG", "PNG", "HEIC", "WEBP"):
            return False, f"不支持的图片格式：{img.format}，请上传 JPEG/PNG/HEIC/WEBP"
        return True, ""
    except Exception as e:
        return False, f"无法解析图片文件：{str(e)}"
