# Google Cloud Workflows 変数メモリ上限検証
## 検証目的
Google Cloud Workflowsのリソース上限として記載されている「変数のメモリ上限 512KB」が、CloudRunからのHTTPレスポンスを変数に格納する際に適用されるかを実機検証する。

### 公式ドキュメントの記載内容

[Quotas and limits | Workflows | Google Cloud](https://cloud.google.com/workflows/quotas)

| 上限項目 | 値 | 説明 |
|---------|-----|------|
| Response size | 2 MB | HTTPレスポンスの最大サイズ（変数に保存する場合は、変数のメモリ上限が適用される） |
| Data size | 512 KB | 変数、引数、イベントの累積最大サイズ |

### 検証したい仮説

> CloudRunから512KBを超えるJSONレスポンスを返却し、Workflows側で変数に格納しようとすると、512KBの上限を超過してエラーになる

## 検証方法

Workflow実行時に引数でサイズ(KB)を指定し、CloudRunがそのサイズのJSONを返却する。同一のWorkflowを引数を変えて3回実行し、結果を比較する。

```bash
# 実行イメージ
gcloud workflows run memory-limit-test-workflow --data='{"size": 400}'
gcloud workflows run memory-limit-test-workflow --data='{"size": 512}'
gcloud workflows run memory-limit-test-workflow --data='{"size": 600}'
```

## 検証環境

| 項目 | 値 |
|------|-----|
| GCPプロジェクト | alert-library-333106 |
| リージョン | asia-northeast1 |
| デプロイ方法 | gcloudコマンド（ソースデプロイ） |
| 認証方式 | サービスアカウント認証 |

## 検証構成図

```
┌──────────────────────────────────────────────────────────────┐
│                         実行者                                │
│                                                               │
│  gcloud workflows run ... --data='{"size": 400}'             │
│  gcloud workflows run ... --data='{"size": 512}'             │
│  gcloud workflows run ... --data='{"size": 600}'             │
└──────────────────────┬───────────────────────────────────────┘
                       │
                       ▼
┌──────────────────────────────────────────────────────────────┐
│                      Workflows                                │
│                                                               │
│  1. 引数から size を取得                                      │
│  2. CloudRun呼び出し: GET /generate?size={size}              │
│  3. レスポンスを result 変数に格納                            │
│  4. 成功時: サイズ情報を返却 / 失敗時: エラー                 │
│                                                               │
└──────────────────────┬───────────────────────────────────────┘
                       │
                       ▼
┌──────────────────────────────────────────────────────────────┐
│                      Cloud Run                                │
│                                                               │
│  GET /generate?size={kb}                                      │
│  → 指定サイズのJSONを生成して返却                             │
│                                                               │
│  レスポンス例:                                                │
│  {                                                            │
│    "requested_size_kb": 400,                                  │
│    "actual_size_bytes": 409600,                               │
│    "padding": "aaaa..."                                       │
│  }                                                            │
└──────────────────────────────────────────────────────────────┘
```

## 作成するリソース

### 1. サービスアカウント

| リソース名 | 用途 |
|-----------|------|
| workflows-invoker-sa | Workflows実行用SA |

付与するロール:
- `roles/run.invoker` (CloudRun呼び出し権限)

### 2. Cloud Run

| 項目 | 値 |
|------|-----|
| サービス名 | memory-limit-test-api |
| ランタイム | Python 3.12 (Flask) |
| 認証 | 認証必須（IAM） |

エンドポイント:
- `GET /generate?size={kb}` - 指定サイズ(KB)のJSONを生成して返却
- `GET /health` - ヘルスチェック用

### 3. Workflows

| 項目 | 値 |
|------|-----|
| ワークフロー名 | memory-limit-test-workflow |
| サービスアカウント | workflows-invoker-sa |

処理フロー:
1. CloudRunに400KBリクエスト → 変数格納 → 成功ログ出力
2. CloudRunに600KBリクエスト → 変数格納 → (エラー発生想定)

## 検証ケース

| ケース | リクエストサイズ | 期待結果 |
|--------|-----------------|----------|
| Case 1 | 400 KB | 成功（512KB未満のため変数に格納される） |
| Case 2 | 512 KB | 境界値（成功または失敗） |
| Case 3 | 600 KB | 失敗（512KB超過によりエラー） |

## ディレクトリ構成

```
workflows-memory-limit-verification/
├── docs/
│   └── 00_verification_plan.md    # 本ドキュメント
├── cloudrun/
│   ├── main.py                    # Flaskアプリ
│   └── requirements.txt           # 依存関係
├── workflows/
│   └── workflow.yaml              # Workflow定義
└── scripts/
    ├── 01_setup_sa.sh             # SA作成スクリプト
    ├── 02_deploy_cloudrun.sh      # CloudRunデプロイ
    ├── 03_deploy_workflow.sh      # Workflowsデプロイ
    ├── 04_execute_test.sh         # 検証実行
    └── 99_cleanup.sh              # リソース削除
```

## 実行手順

1. サービスアカウント作成 (`01_setup_sa.sh`)
2. CloudRunデプロイ (`02_deploy_cloudrun.sh`)
3. Workflowsデプロイ (`03_deploy_workflow.sh`)
4. 検証実行 (`04_execute_test.sh`)
5. 結果確認・ブログ用スクリーンショット取得
6. リソース削除 (`99_cleanup.sh`)

## 備考

- 検証完了後はリソースを削除してコスト発生を防ぐ
- エラーメッセージの内容も記録してブログに掲載する

