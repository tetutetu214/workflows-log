#!/bin/bash
set -euo pipefail

# =============================================================================
# 03_deploy_workflow.sh
# 検証用Workflowをデプロイする
# =============================================================================

PROJECT_ID="alert-library-333106"
REGION="asia-northeast1"
WORKFLOW_NAME="memory-limit-test-workflow"
SA_NAME="workflows-invoker-sa"
SA_EMAIL="${SA_NAME}@${PROJECT_ID}.iam.gserviceaccount.com"
SERVICE_NAME="memory-limit-test-api"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
WORKFLOW_FILE="${SCRIPT_DIR}/../workflows/workflow.yaml"

echo "=========================================="
echo "Workflowsデプロイ開始"
echo "=========================================="
echo "Project: ${PROJECT_ID}"
echo "Region: ${REGION}"
echo "Workflow: ${WORKFLOW_NAME}"
echo ""

# プロジェクト設定
gcloud config set project ${PROJECT_ID}

# CloudRun URLを取得
CLOUDRUN_URL=$(gcloud run services describe ${SERVICE_NAME} \
    --region ${REGION} \
    --format "value(status.url)")

echo "CloudRun URL: ${CLOUDRUN_URL}"
echo ""

# Workflowデプロイ
echo "[1/1] Workflowデプロイ中..."
gcloud workflows deploy ${WORKFLOW_NAME} \
    --location ${REGION} \
    --source ${WORKFLOW_FILE} \
    --service-account ${SA_EMAIL} \
    --set-env-vars "CLOUDRUN_URL=${CLOUDRUN_URL}"

echo ""
echo "=========================================="
echo "Workflowsデプロイ完了"
echo "=========================================="
echo "Workflow: ${WORKFLOW_NAME}"
echo "Location: ${REGION}"
