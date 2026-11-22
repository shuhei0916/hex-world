#!/usr/bin/env bash
# hex-world のデータをヘッドレスの Godot で書き出し、他のゲームと同じ形で集計する。
#   tools/research/hex_world.sh            → docs/research/hex_world/generated/
#   tools/research/hex_world.sh <出力先>
set -euo pipefail

root="$(cd "$(dirname "$0")/../.." && pwd)"
out="${1:-$root/docs/research/hex_world/generated}"
mkdir -p "$out"
json="$(cd "$out" && pwd)/hex_world.json"

EXPORT_PATH="$json" "$root/.claude/skills/godot-run/scripts/dump_tree.sh" \
	"--do=script:res://tools/scenarios/export_game_data.gd" --depth=0 >/dev/null
python -I "$root/tools/research/hex_world.py" "$json" "$out"
