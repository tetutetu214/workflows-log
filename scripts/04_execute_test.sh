#!/bin/bash
set -euo pipefail

# =============================================================================
# 04_execute_test.sh
# 検証を実行する
# =============================================================================

PROJECT_ID="alert-library-333106"
REGION="asia-northeast1"
WORKFLOW_NAME="memory-limit-test-workflow"

echo "=========================================="
echo "Workflows変数メモリ上限検証"
echo "=========================================="
echo ""

# プロジェクト設定
gcloud config set project ${PROJECT_ID}

# 検証ケース定義
TEST_CASES=(400 512 600)

for SIZE in "${TEST_CASES[@]}"; do
    echo "=========================================="
    echo "Case: ${SIZE}KB"
    echo "=========================================="

    echo "[実行中] size=${SIZE}KB..."
    echo ""

    # Workflow実行（同期実行）
    set +e
    RESULT=$(gcloud workflows run ${WORKFLOW_NAME} \
        --location ${REGION} \
        --data="{\"size\": ${SIZE}}" \
        --format="yaml" \
        2>&1)
    EXIT_CODE=$?
    set -e

    echo "--- 実行結果 ---"
    echo "${RESULT}"
    echo ""

    if [ ${EXIT_CODE} -eq 0 ]; then
        echo "[結果] 成功"
    else
        echo "[結果] 失敗 (exit code: ${EXIT_CODE})"
    fi

    echo ""
    echo ""
done

echo "=========================================="
echo "検証完了"
echo "=========================================="
