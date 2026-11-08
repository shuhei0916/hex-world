#!/usr/bin/env bash
# GUT で tests/ 以下の全テスト（サブディレクトリ含む）を実行する。
# 追加引数は GUT にそのまま渡す（例: -gselect=test_world.gd / -gunit_test_name=hover）
set -eu
SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
PROJECT_DIR=$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)
GODOT_BIN=$("$SCRIPT_DIR/find_godot.sh")

cd "$PROJECT_DIR"
# class_name キャッシュやインポートを最新化（新規ファイル追加直後の誤検知を防ぐ）
"$GODOT_BIN" --headless --import >/dev/null 2>&1 || true
"$GODOT_BIN" --headless --script addons/gut/gut_cmdln.gd \
	-gdir=res://tests/ -ginclude_subdirs -gexit "$@"
