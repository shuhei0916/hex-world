class_name GridDisplay
extends Node2D

# GridDisplay - グリッド表示システム
# Hexグリッドの視覚化を担当

var layout: Layout
var grid_hexes: Array[Hex] = []

func _init():
	# レイアウト設定（Pieceと同じ設定で統一）
	layout = Layout.new(
		Layout.layout_pointy,
		Vector2(0.6, 0.6),
		Vector2(0.0, 0.0)
	)

# 六角形グリッドを作成（半径指定）
func create_hex_grid(radius: int):
	grid_hexes.clear()
	
	# 中心を原点として半径内のすべてのhexを生成
	for q in range(-radius, radius + 1):
		var r1 = max(-radius, -q - radius)
		var r2 = min(radius, -q + radius)
		for r in range(r1, r2 + 1):
			var hex = Hex.new(q, r)
			grid_hexes.append(hex)

# グリッドのhex数を取得
func get_grid_hex_count() -> int:
	return grid_hexes.size()

# Hex座標をピクセル座標に変換
func hex_to_pixel(hex: Hex) -> Vector2:
	return Layout.hex_to_pixel(layout, hex)

# GridManagerにグリッドを登録
func register_grid_with_manager():
	for hex in grid_hexes:
		GridManager.register_grid_hex(hex)

# グリッドを視覚的に描画（将来の拡張用）
func draw_grid():
	# TODO: 実際の描画機能は後で実装
	pass