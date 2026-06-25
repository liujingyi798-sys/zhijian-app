FROM python:3.12-slim

WORKDIR /app

# Minimal system deps for Python packages
RUN apt-get update && apt-get install -y --no-install-recommends \
    libgl1 libglib2.0-0t64 libsm6 libxext6 libxrender1 libgomp1 \
    && rm -rf /var/lib/apt/lists/*

COPY backend/requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY backend/ .

RUN mkdir -p /app/uploads

EXPOSE 8000

CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]
