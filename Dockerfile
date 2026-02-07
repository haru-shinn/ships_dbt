# Dockerfile
# ベースイメージはPython 3.12.4
FROM python:3.12.4-slim-bookworm AS base

# 作業ディレクトリを設定
WORKDIR /app

# 必要なパッケージのインストールと不要なキャッシュのクリーンアップ
# build-essential: dbt-bigqueryのC拡張コンパイル用
# git, ssh-client, curl: 開発・デバッグ用
# vim: コンテナ内での簡易編集用
# apt-transport-https, ca-certificates, gnupg: gcloud CLIインストール用
RUN apt-get update \
  && apt-get upgrade -y \
  && apt-get install -y --no-install-recommends \
    build-essential \
    git \
    ssh-client \
    curl \
    vim \
    apt-transport-https \
    ca-certificates \
    gnupg \
  && apt-get clean \
  && rm -rf \
    /var/lib/apt/lists/* \
    /tmp/* \
    /var/tmp/*

# gcloud CLIのインストール (apt-key.gpg のダウンロードとリポジトリ追加)
RUN curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | gpg --dearmor -o /usr/share/keyrings/cloud.google.gpg \
    && echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" > /etc/apt/sources.list.d/google-cloud-sdk.list \
    && apt-get update \
    && apt-get install -y google-cloud-sdk \
    && rm -rf /var/lib/apt/lists/*

# Pythonパッケージをインストール
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# 環境変数
ENV PYTHONIOENCODING=utf-8
ENV LANG C.UTF-8

# dbt のバージョン確認 (オプション)
RUN dbt --version

# コンテナ起動時のデフォルトコマンド
CMD ["dbt"]