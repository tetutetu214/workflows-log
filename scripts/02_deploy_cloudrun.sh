#!/bin/bash
set -euo pipefail

# =============================================================================
# 02_deploy_cloudrun.sh
# 検証用CloudRunサービスをデプロイする
# =============================================================================

PROJECT_ID="alert-library-333106"
REGION="asia-northeast1"
SERVICE_NAME="memory-limit-test-api"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CLOUDRUN_DIR="${SCRIPT_DIR}/../cloudrun"

echo "=========================================="
echo "CloudRunデプロイ開始"
echo "=========================================="
echo "Project: ${PROJECT_ID}"
echo "Region: ${REGION}"
echo "Service: ${SERVICE_NAME}"
echo ""

# プロジェクト設定
gcloud config set project ${PROJECT_ID}

# ソースからデプロイ
echo "[1/1] CloudRunデプロイ中..."
gcloud run deploy ${SERVICE_NAME} \
    --source ${CLOUDRUN_DIR} \
    --region ${REGION} \
    --platform managed \
    --no-allow-unauthenticated \
    --memory 512Mi \
    --timeout 60 \
    --quiet

# デプロイされたURLを取得
CLOUDRUN_URL=$(gcloud run services describe ${SERVICE_NAME} \
    --region ${REGION} \
    --format "value(status.url)")

echo ""
echo "=========================================="
echo "CloudRunデプロイ完了"
echo "=========================================="
echo "Service URL: ${CLOUDRUN_URL}"
echo ""
echo "次のステップで使用するため、このURLをメモしてください。"
