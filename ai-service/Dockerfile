FROM python:3.11-slim
WORKDIR /app

ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1
ENV AI_SERVICE_HOST=0.0.0.0
ENV AI_SERVICE_PORT=8000

COPY requirements.txt ./
RUN pip install --no-cache-dir -r requirements.txt

COPY app ./app

EXPOSE 8000
CMD ["sh", "-c", "uvicorn app.main:app --host ${AI_SERVICE_HOST} --port ${AI_SERVICE_PORT}"]
