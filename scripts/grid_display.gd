@tool
class_name GridDisplay
extends Node2D

# GridDisplay - グリッド表示システム
# Hexグリッドの視覚化を担当

signal grid_updated(hexes: Array[Hex])

var layout: Layout
var grid_hexes: Array[Hex] = []
var hex_tile_scene = preload("res://scenes/HexTile.tscn")  # hexPrefab相当

@export var grid_radius: int = 4:
	set(value):
		if value == grid_radius:
			return
		grid_radius = value
		if not is_inside_tree():
			return
		_update_grid_visuals()


func _init():
	# レイアウト設定（視覚化用に大きめサイズ）
	layout = Layout.new(
		Layout.layout_pointy,
		Vector2(42.0, 42.0),  # より大きなサイズで視覚化
		Vector2(0.0, 0.0)
	)

func _ready():
	_update_grid_visuals()

func _update_grid_visuals():
	# 既存のhex表示をクリア
	while get_child_count() > 0:
		var child = get_child(0)
		remove_child(child)
		child.queue_free()

	create_hex_grid(grid_radius)
	draw_grid()

# 六角形グリッドを作成（半径指定）
func create_hex_grid(radius: int):
	grid_radius = radius  # グリッド半径を保存
	grid_hexes.clear()

	# 中心を原点として半径内のすべてのhexを生成
	for q in range(-radius, radius + 1):
		var r1 = max(-radius, -q - radius)
		var r2 = min(radius, -q + radius)
		for r in range(r1, r2 + 1):
			var hex = Hex.new(q, r)
			grid_hexes.append(hex)
	
	grid_updated.emit(grid_hexes)


# グリッドのhex数を取得
func get_grid_hex_count() -> int:
	return grid_hexes.size()


# Hex座標をピクセル座標に変換
func hex_to_pixel(hex: Hex) -> Vector2:
	return Layout.hex_to_pixel(layout, hex)


# グリッドを視覚的に描画（Unity風Instantiate実装）
func draw_grid():
	if not Engine.is_editor_hint():
		print("draw_grid() started with %d hexes" % grid_hexes.size())

	# Unity: Instantiate(hexPrefab, pos, Quaternion.identity, transform)
	for i in range(grid_hexes.size()):
		var hex = grid_hexes[i]
		var world_pos = hex_to_pixel(hex)  # pos相当
		var hex_instance = hex_tile_scene.instantiate()  # Instantiate相当
		hex_instance.position = world_pos  # Quaternion.identity + pos設定
		add_child(hex_instance)  # transform相当でNode2Dツリーに追加
		hex_instance.setup_hex(hex)  # hex座標情報設定（デフォルト色設定も含む）

		# 最初の数個の座標をデバッグログ出力
		if not Engine.is_editor_hint() and i < 3:
			print("Hex[%d]: coord(%d,%d) -> world_pos(%s)" % [i, hex.q, hex.r, world_pos])

	if not Engine.is_editor_hint():
		print("draw_grid() completed. Child count: %d" % get_child_count())


# 経路をハイライト表示
func highlight_path(hex_path: Array[Hex]):
	# 既存のハイライトをクリア
	clear_path_highlight()

	# 経路上の各hexをハイライト
	for hex in hex_path:
		var hex_tile = find_hex_tile(hex)
		if hex_tile:
			hex_tile.set_highlight(true)


# 経路を始点付きでハイライト表示
func highlight_path_with_start(hex_path: Array[Hex], start_hex: Hex):
	# 既存のハイライトをクリア
	clear_path_highlight()

	# 始点（プレイヤーの現在地）をハイライト
	if start_hex:
		var start_tile = find_hex_tile(start_hex)
		if start_tile:
			start_tile.set_highlight(true)

	# 経路上の各hexをハイライト
	for hex in hex_path:
		var hex_tile = find_hex_tile(hex)
		if hex_tile:
			hex_tile.set_highlight(true)


# ハイライトをクリア
func clear_path_highlight():
	for child in get_children():
		if child.has_method("set_highlight"):
			child.set_highlight(false)



# hex座標に対応するHexTileを検索
func find_hex_tile(target_hex: Hex) -> HexTile:
	for child in get_children():
		if child.has_method("setup_hex") and child.hex_coordinate:
			if Hex.equals(child.hex_coordinate, target_hex):
				return child
	return null


# hex座標がグリッド境界内かを判定
func is_within_bounds(hex_coord: Hex) -> bool:
	if not hex_coord:
		return false

	# hex座標の原点からの距離を計算
	var distance = Hex.distance(Hex.new(0, 0), hex_coord)

	# グリッド半径以内であれば境界内
	return distance <= grid_radius
