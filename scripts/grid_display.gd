class_name GridDisplay
extends Node2D

# GridDisplay - グリッド表示システム
# Hexグリッドの視覚化を担当

var layout: Layout
var grid_hexes: Array[Hex] = []
var hex_tile_scene = preload("res://scenes/HexTile.tscn")  # hexPrefab相当

func _init():
	# レイアウト設定（視覚化用に大きめサイズ）
	layout = Layout.new(
		Layout.layout_pointy,
		Vector2(42.0, 42.0),  # より大きなサイズで視覚化
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

# 既存のhex表示をクリア
func clear_existing_hexes():
	for child in get_children():
		child.queue_free()

# グリッドを視覚的に描画（Unity風Instantiate実装）
func draw_grid():
	print("draw_grid() started with %d hexes" % grid_hexes.size())
	
	# 既存のhex表示をクリア
	clear_existing_hexes()
	
	# Unity: Instantiate(hexPrefab, pos, Quaternion.identity, transform)
	for i in range(grid_hexes.size()):
		var hex = grid_hexes[i]
		var world_pos = hex_to_pixel(hex)  # pos相当
		var hex_instance = hex_tile_scene.instantiate()  # Instantiate相当
		hex_instance.position = world_pos  # Quaternion.identity + pos設定
		add_child(hex_instance)  # transform相当でNode2Dツリーに追加
		hex_instance.setup_hex(hex)  # hex座標情報設定
		hex_instance.get_node("Sprite2D").modulate = Color("#3D3D3D")
		
		# 最初の数個の座標をデバッグログ出力
		if i < 3:
			print("Hex[%d]: coord(%d,%d) -> world_pos(%s)" % [i, hex.q, hex.r, world_pos])
	
	print("draw_grid() completed. Child count: %d" % get_child_count())
