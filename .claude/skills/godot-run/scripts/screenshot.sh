#!/usr/bin/env bash
# 描画ありでシーンを起動し、入力シナリオを流してスクリーンショットを撮る（ウィンドウが一瞬開く）。
# 引数は dump_tree.sh と同じ。撮影は --do の中の shot:<絶対パス.png> ステップで行う。
#   screenshot.sh "--do=wait:10;shot:C:/tmp/a.png" --depth=0
# ウィンドウの大きさは --resolution で決まる（既定 1280x720）
set -eu
SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
PROJECT_DIR=$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)
GODOT_BIN=$("$SCRIPT_DIR/find_godot.sh")
RESOLUTION=${RESOLUTION:-1280x720}

cd "$PROJECT_DIR"
"$GODOT_BIN" --headless --import >/dev/null 2>&1 || true
"$GODOT_BIN" --resolution "$RESOLUTION" --script res://tools/dump_scene_tree.gd -- "$@"
