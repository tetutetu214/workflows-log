#!/bin/bash
set -euo pipefail

# =============================================================================
# 99_cleanup.sh
# 検証用リソースを削除する
# =============================================================================

PROJECT_ID="alert-library-333106"
REGION="asia-northeast1"
WORKFLOW_NAME="memory-limit-test-workflow"
SERVICE_NAME="memory-limit-test-api"
SA_NAME="workflows-invoker-sa"
SA_EMAIL="${SA_NAME}@${PROJECT_ID}.iam.gserviceaccount.com"

echo "=========================================="
echo "リソース削除開始"
echo "=========================================="
echo ""
echo "以下のリソースを削除します:"
echo "  - Workflow: ${WORKFLOW_NAME}"
echo "  - CloudRun: ${SERVICE_NAME}"
echo "  - ServiceAccount: ${SA_NAME}"
echo ""
read -p "続行しますか？ (y/N): " CONFIRM
if [[ "${CONFIRM}" != "y" && "${CONFIRM}" != "Y" ]]; then
    echo "キャンセルしました。"
    exit 0
fi
echo ""

# プロジェクト設定
gcloud config set project ${PROJECT_ID}

# Workflow削除
echo "[1/3] Workflow削除..."
if gcloud workflows describe ${WORKFLOW_NAME} --location ${REGION} > /dev/null 2>&1; then
    gcloud workflows delete ${WORKFLOW_NAME} --location ${REGION} --quiet
    echo "  → 削除完了"
else
    echo "  → 存在しません。スキップ。"
fi

# CloudRun削除
echo "[2/3] CloudRun削除..."
if gcloud run services describe ${SERVICE_NAME} --region ${REGION} > /dev/null 2>&1; then
    gcloud run services delete ${SERVICE_NAME} --region ${REGION} --quiet
    echo "  → 削除完了"
else
    echo "  → 存在しません。スキップ。"
fi

# サービスアカウント削除
echo "[3/3] サービスアカウント削除..."
if gcloud iam service-accounts describe ${SA_EMAIL} > /dev/null 2>&1; then
    gcloud iam service-accounts delete ${SA_EMAIL} --quiet
    echo "  → 削除完了"
else
    echo "  → 存在しません。スキップ。"
fi

echo ""
echo "=========================================="
echo "リソース削除完了"
echo "=========================================="
