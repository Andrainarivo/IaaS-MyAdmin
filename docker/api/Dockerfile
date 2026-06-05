FROM python:3.12-slim

# Évite que Python écrive des fichiers .pyc et désactive le buffering pour une meilleure visibilité des logs
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

WORKDIR /app

RUN apt-get update && apt-get install -y --no-install-recommends \
    git \
    && rm -rf /var/lib/apt/lists/*

ARG GIT_COMMIT_SHA=main

RUN rm -rf * .git 2>/dev/null || true

RUN git clone https://github.com/Andrainarivo/MyAdmin.git . \
    && git checkout ${GIT_COMMIT_SHA} \
    && rm -rf .git

RUN pip install --no-cache-dir --upgrade pip \
    && pip install --no-cache-dir -r requirements.txt


EXPOSE 8000

CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]