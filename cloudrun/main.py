"""
Workflows変数メモリ上限検証用API

指定されたサイズ(KB)のJSONレスポンスを生成して返却する。
"""
import os

from flask import Flask, jsonify, request


app = Flask(__name__)

BYTES_PER_KB = 1024


@app.route("/health", methods=["GET"])
def health():
    """ヘルスチェック用エンドポイント"""
    return jsonify({"status": "healthy"})


@app.route("/generate", methods=["GET"])
def generate():
    """
    指定サイズのJSONを生成して返却する。

    Query Parameters:
        size: 生成するJSONのサイズ(KB)

    Returns:
        JSON: requested_size_kb, actual_size_bytes, padding を含むレスポンス
    """
    size_kb = request.args.get("size", type=int)

    if size_kb is None:
        return jsonify({"error": "size parameter is required"}), 400

    if size_kb <= 0:
        return jsonify({"error": "size must be positive"}), 400

    if size_kb > 3000:
        return jsonify({"error": "size must be 3000KB or less"}), 400

    target_bytes = size_kb * BYTES_PER_KB

    base_response = {
        "requested_size_kb": size_kb,
        "actual_size_bytes": 0,
        "padding": "",
    }

    import json
    base_size = len(json.dumps(base_response))

    padding_size = target_bytes - base_size
    if padding_size < 0:
        padding_size = 0

    padding = "a" * padding_size

    response = {
        "requested_size_kb": size_kb,
        "actual_size_bytes": target_bytes,
        "padding": padding,
    }

    actual_size = len(json.dumps(response))
    response["actual_size_bytes"] = actual_size

    return jsonify(response)


if __name__ == "__main__":
    port = int(os.environ.get("PORT", 8080))
    app.run(host="0.0.0.0", port=port)
