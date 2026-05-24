FROM python:3.12-slim

RUN pip install --no-cache-dir flask

COPY app.py /app.py

CMD ["python", "/app.py"]
#CMD ["gunicorn", "--bind", "0.0.0.0:5000", "--workers", "1", "app:app", "--chdir", "/"]
