# ==========================================================
# ステージ 1: ビルダー (Build Stage)
# ==========================================================
FROM python:3.12-slim AS builder

ENV PYTHONUNBUFFERED=1 PYTHONDONTWRITEBYTECODE=1
WORKDIR /app

RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential curl ca-certificates \
    && rm -rf /var/lib/apt/lists/*

COPY requirements.txt .
RUN pip install --no-cache-dir --prefix=/install -r requirements.txt

# ==========================================================
# ステージ 2: 開発環境 (Development Stage - Dev Containers用)
# ==========================================================
FROM python:3.12-slim AS development

ENV PYTHONUNBUFFERED=1 PYTHONDONTWRITEBYTECODE=1 TZ=Asia/Tokyo \
    DBT_PROFILES_DIR=/app/dbt_project \
    DBT_SA_KEYS_PATH=/app/.gcp/keyfile.json

WORKDIR /app

# 開発に必要なツールをすべて入れる
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential git ssh-client curl ca-certificates gnupg vim \
    && rm -rf /var/lib/apt/lists/*

# ビルダーからライブラリをコピー
COPY --from=builder /install /usr/local

# 開発時は root で作業することが多いですが、必要に応じてユーザー切り替えも可能
CMD ["bash"]

# ==========================================================
# ステージ 3: 実行環境 (Final Stage - 本番デプロイ用)
# ==========================================================
FROM python:3.12-slim AS production

ENV PYTHONUNBUFFERED=1 PYTHONDONTWRITEBYTECODE=1 TZ=Asia/Tokyo \
    DBT_PROFILES_DIR=/app/dbt_project \
    DBT_SA_KEYS_PATH=/app/.gcp/keyfile.json

WORKDIR /app

# 本番に必要な最小限のツール（gcloud等）
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl ca-certificates gnupg \
    && rm -rf /var/lib/apt/lists/*

RUN groupadd -r app && useradd -r -g app app \
    && mkdir -p /app/.dbt /app/dbt_project && chown -R app:app /app

# ビルダーからライブラリをコピー
COPY --from=builder /install /usr/local

USER app
# 本番用ファイルのコピー（CI/CDビルド時に実行される）
COPY --chown=app:app . .