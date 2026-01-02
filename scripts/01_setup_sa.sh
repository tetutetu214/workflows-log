#!/bin/bash
set -euo pipefail

# =============================================================================
# 01_setup_sa.sh
# Workflows実行用サービスアカウントを作成する
# =============================================================================

PROJECT_ID="alert-library-333106"
REGION="asia-northeast1"
SA_NAME="workflows-invoker-sa"
SA_EMAIL="${SA_NAME}@${PROJECT_ID}.iam.gserviceaccount.com"

echo "=========================================="
echo "サービスアカウント作成開始"
echo "=========================================="
echo "Project: ${PROJECT_ID}"
echo "SA Name: ${SA_NAME}"
echo ""

# プロジェクト設定
gcloud config set project ${PROJECT_ID}

# サービスアカウント作成
echo "[1/2] サービスアカウント作成..."
if gcloud iam service-accounts describe ${SA_EMAIL} > /dev/null 2>&1; then
    echo "  → 既に存在します。スキップ。"
else
    gcloud iam service-accounts create ${SA_NAME} \
        --display-name="Workflows Invoker SA for memory limit test"
    echo "  → 作成完了"
fi

# Cloud Run起動権限を付与
echo "[2/2] Cloud Run Invokerロール付与..."
gcloud projects add-iam-policy-binding ${PROJECT_ID} \
    --member="serviceAccount:${SA_EMAIL}" \
    --role="roles/run.invoker" \
    --condition=None \
    --quiet

echo ""
echo "=========================================="
echo "サービスアカウント作成完了"
echo "=========================================="
echo "SA Email: ${SA_EMAIL}"
