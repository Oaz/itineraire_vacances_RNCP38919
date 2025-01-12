FROM python:3.9-slim

WORKDIR /app
COPY api/requirements.txt .
COPY api/app.py .

RUN pip install --no-cache-dir -r requirements.txt

EXPOSE 5000

CMD ["uvicorn", "app:app", "--host", "0.0.0.0", "--port", "5000"]

