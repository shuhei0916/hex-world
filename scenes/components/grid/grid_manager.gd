@tool
extends Node2D

# GridManager - グリッドの論理的な状態と視覚的な表示を管理する
# Unity版のGridManager.csとGridDisplayの機能を統合

signal grid_updated(hexes: Array[Hex]) # GridDisplayから移動

# 論理グリッドの状態
var _registered_hexes: Dictionary = {} # GridManagerから移動
var _occupied_hexes: Dictionary = {} # GridManagerから移動

# 視覚グリッドの状態
var layout: Layout # GridDisplayから移動
var _drawn_hexes: Array[Hex] = [] # GridDisplayのgrid_hexesからリネーム
var hex_tile_scene = preload("res://scenes/components/hex_tile/hex_tile.tscn")

@export var grid_radius: int = 4: # GridDisplayから移動
	set(value):
		if value == grid_radius:
			return
		grid_radius = value
		if not is_inside_tree(): # _ready前に値を変更した場合は何もしない
			return
		_update_grid_visuals() # ビジュアルを更新

func _init():
	# GridManagerの_init: シングルトンからノードになったので、毎回クリアする意味は薄いが、念のため残す
	_registered_hexes.clear()
	_occupied_hexes.clear()
	
	# GridDisplayの_init: レイアウト設定（視覚化用に大きめサイズ）
	layout = Layout.new(
		Layout.layout_pointy,
		Vector2(42.0, 42.0), # より大きなサイズで視覚化
		Vector2(0.0, 0.0)
	)

func _ready():
	# GridManagerの_ready: 無し
	# GridDisplayの_ready: ビジュアルを更新
	_update_grid_visuals()
	
	# エディタで実行時のみメッセージ
	if not Engine.is_editor_hint():
		print("GridManager (Node2D) initialized")

# ==============================================================================
# 論理グリッド管理 (旧 GridManager の機能)
# ==============================================================================

# グリッドのhexを登録 (旧 GridManager.register_grid_hex)
func register_grid_hex(hex: Hex):
	var key = _hex_to_key(hex)
	_registered_hexes[key] = hex

# グリッド内かどうかを判定 (旧 GridManager.is_inside_grid)
func is_inside_grid(hex: Hex) -> bool:
	var key = _hex_to_key(hex)
	return _registered_hexes.has(key)

# hexが占有されているかを判定 (旧 GridManager.is_occupied)
func is_occupied(hex: Hex) -> bool:
	var key = _hex_to_key(hex)
	return _occupied_hexes.has(key)

# hexを占有する (旧 GridManager.occupy)
func occupy(hex: Hex):
	var key = _hex_to_key(hex)
	_occupied_hexes[key] = hex

# 複数のhexを占有する (旧 GridManager.occupy_many)
func occupy_many(hexes: Array):
	for hex in hexes:
		occupy(hex)

# ピースが配置可能かを判定 (旧 GridManager.can_place)
func can_place(shape: Array, base_hex: Hex) -> bool:
	for offset in shape:
		var target = Hex.add(base_hex, offset)
		if not is_inside_grid(target):
			return false
		if is_occupied(target):
			return false
	return true

# ピースを配置する (旧 GridManager.place_piece)
func place_piece(shape: Array, base_hex: Hex, piece_color: Color):
	for offset in shape:
		var target = Hex.add(base_hex, offset)
		occupy(target)
		
		# 配置されたHexTileの色を更新
		var hex_tile = find_hex_tile(target)
		if hex_tile:
			hex_tile.set_color(piece_color)

# ピースを解除する (旧 GridManager.unplace_piece)
func unplace_piece(shape: Array, base_hex: Hex):
	for offset in shape:
		var target = Hex.add(base_hex, offset)
		var key = _hex_to_key(target)
		_occupied_hexes.erase(key)

# グリッド状態をクリア（テスト用） (旧 GridManager.clear_grid)
func clear_grid():
	_registered_hexes.clear()
	_occupied_hexes.clear()

# HexをDictionary keyに変換するヘルパー (旧 GridManager._hex_to_key)
func _hex_to_key(hex: Hex) -> String:
	return "%d,%d,%d" % [hex.q, hex.r, hex.s]

# ==============================================================================
# 視覚グリッド管理 (旧 GridDisplay の機能)
# ==============================================================================

func _update_grid_visuals(): # GridDisplayから移動
	# 既存のhex表示をクリア
	while get_child_count() > 0:
		var child = get_child(0)
		remove_child(child)
		child.queue_free()

	create_hex_grid(grid_radius)
	draw_grid()

# 六角形グリッドを作成（半径指定） (旧 GridDisplay.create_hex_grid)
func create_hex_grid(radius: int):
	grid_radius = radius # グリッド半径を保存
	_drawn_hexes.clear()

	# 中心を原点として半径内のすべてのhexを生成
	for q in range(-radius, radius + 1):
		var r1 = max(-radius, -q - radius)
		var r2 = min(radius, -q + radius)
		for r in range(r1, r2 + 1):
			var hex = Hex.new(q, r)
			_drawn_hexes.append(hex)
	
	# _drawn_hexesの内容を登録済みhexesにコピー
	for hex in _drawn_hexes:
		register_grid_hex(hex)

	grid_updated.emit(_drawn_hexes) # シグナル発火

# グリッドのhex数を取得 (旧 GridDisplay.get_grid_hex_count)
func get_grid_hex_count() -> int:
	return _drawn_hexes.size()

# Hex座標をピクセル座標に変換 (旧 GridDisplay.hex_to_pixel)
func hex_to_pixel(hex: Hex) -> Vector2:
	return Layout.hex_to_pixel(layout, hex)

# グリッドを視覚的に描画 (旧 GridDisplay.draw_grid)
func draw_grid():
	if not Engine.is_editor_hint():
		print("draw_grid() started with %d hexes" % _drawn_hexes.size())

	# Unity: Instantiate(hexPrefab, pos, Quaternion.identity, transform)
	for i in range(_drawn_hexes.size()):
		var hex = _drawn_hexes[i]
		var world_pos = hex_to_pixel(hex) # pos相当
		var hex_instance = hex_tile_scene.instantiate() # Instantiate相当
		hex_instance.position = world_pos # Quaternion.identity + pos設定
		add_child(hex_instance) # transform相当でNode2Dツリーに追加
		hex_instance.setup_hex(hex) # hex座標情報設定（デフォルト色設定も含む）

		# 最初の数個の座標をデバッグログ出力
		if not Engine.is_editor_hint() and i < 3:
			print("Hex[%d]: coord(%d,%d) -> world_pos(%s)" % [i, hex.q, hex.r, world_pos])

	if not Engine.is_editor_hint():
		print("draw_grid() completed. Child count: %d" % get_child_count())

# 経路をハイライト表示 (旧 GridDisplay.highlight_path)
func highlight_path(hex_path: Array[Hex]):
	# 既存のハイライトをクリア
	clear_path_highlight()

	# 経路上の各hexをハイライト
	for hex in hex_path:
		var hex_tile = find_hex_tile(hex)
		if hex_tile:
			hex_tile.set_highlight(true)

# 経路を始点付きでハイライト表示 (旧 GridDisplay.highlight_path_with_start)
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

# ハイライトをクリア (旧 GridDisplay.clear_path_highlight)
func clear_path_highlight():
	for child in get_children():
		if child.has_method("set_highlight"):
			child.set_highlight(false)

# hex座標に対応するHexTileを検索 (旧 GridDisplay.find_hex_tile)
func find_hex_tile(target_hex: Hex) -> HexTile:
	for child in get_children():
		if child.has_method("setup_hex") and child.hex_coordinate:
			if Hex.equals(child.hex_coordinate, target_hex):
				return child
	return null

# hex座標がグリッド境界内かを判定 (旧 GridDisplay.is_within_bounds)
func is_within_bounds(hex_coord: Hex) -> bool:
	if not hex_coord:
		return false

	# _drawn_hexesの中から探すことで、現在描画されているグリッドの範囲内かを確認
	# もし論理的な範囲だけをGridManagerで管理したいなら_registered_hexesを見るべき
	var key = _hex_to_key(hex_coord)
	return _registered_hexes.has(key)
