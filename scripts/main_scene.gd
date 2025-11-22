extends Node2D

# MainScene - 工場設計ゲームのメインシーン制御
# Hex工場設計システムのメインシーン管理

const HEX_TILE_SCENE := preload("res://scenes/HexTile.tscn")

@onready var grid_display = $GridDisplay
@onready var camera = $Camera2D
@onready var palette_ui = $UILayer/PaletteUI
@onready var preview_layer = $PreviewLayer
@onready var pieces_layer = $PiecesLayer
var debug_mode: bool = false
var preview_root: Node2D = null
var preview_piece_data: Dictionary = {}
var preview_target_hex: Hex = null
var preview_cells: Array[Hex] = []
const PREVIEW_ALPHA := 0.4

func _ready():
	print("MainScene initialized")
	setup_game()
	if palette_ui:
		var palette = palette_ui.get_palette()
		if palette:
			palette.connect("active_slot_changed", Callable(self, "_on_active_palette_slot_changed"))
	_update_preview_piece()
	_update_preview_for_current_mouse()

func _process(_delta):
	update_debug_display()
	_update_preview_for_current_mouse()

func _input(event):
	if palette_ui:
		palette_ui.process_input_event(event)
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_F2:
			toggle_debug_mode()
	elif event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_RIGHT:
			place_preview_piece()
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP:
			zoom_camera(1.1)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			zoom_camera(0.9)
	elif event is InputEventMouseMotion:
		if Input.is_action_pressed("ui_select"):  # マウス中ボタンでカメラパン
			pan_camera(-event.relative)

func setup_game():
	# グリッド設定（工場設計用の中規模グリッド）
	if grid_display:
		grid_display.create_hex_grid(4)  # 半径6の六角形グリッド（工場設計用に拡大）
		grid_display.register_grid_with_manager()
		print("Factory grid created with %d hexes" % grid_display.get_grid_hex_count())
		
		# グリッドを視覚的に描画
		grid_display.draw_grid()
		print("Grid drawing completed with %d visual tiles" % grid_display.get_child_count())
		
		# カメラの初期設定
		setup_camera()

# マウス座標からhex座標を取得
func get_hex_at_mouse_position(mouse_position: Vector2) -> Hex:
	if grid_display:
		return Layout.pixel_to_hex_rounded(grid_display.layout, mouse_position)
	else:
		# フォールバック: グリッドがない場合は原点のhexを返す
		return Hex.new(0, 0)

# デバッグ表示を更新
func update_debug_display():
	if not is_inside_tree():
		return
	var debug_label = get_node("DebugLabel")
	if debug_label:
		var mouse_pos = get_global_mouse_position()
		var hex_coord = get_hex_at_mouse_position(mouse_pos)
		debug_label.text = "Hex: (%2d, %2d)" % [hex_coord.q, hex_coord.r]

# デバッグモードをトグル
func toggle_debug_mode():
	debug_mode = !debug_mode
	print("Debug mode: %s" % ("ON" if debug_mode else "OFF"))
	update_hex_overlay_display()

# hexタイルの座標オーバーレイ表示を更新
func update_hex_overlay_display():
	if not grid_display:
		return
	
	# 全てのhex_tileに対してCoordLabelの表示を切り替え
	for hex_tile in grid_display.get_children():
		if hex_tile.has_method("setup_hex"):  # HexTileインスタンスの確認
			var coord_label = hex_tile.get_node_or_null("CoordLabel")
			
			if debug_mode:
				# デバッグモードON: Labelを作成または表示
				if not coord_label:
					coord_label = Label.new()
					coord_label.name = "CoordLabel"
					coord_label.add_theme_font_size_override("font_size", 12)
					coord_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
					coord_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
					hex_tile.add_child(coord_label)
				
				# hex座標をテキストとして設定
				if hex_tile.hex_coordinate:
					coord_label.text = "(%d,%d)" % [hex_tile.hex_coordinate.q, hex_tile.hex_coordinate.r]
				coord_label.visible = true
			else:
				# デバッグモードOFF: Labelを非表示
				if coord_label:
					coord_label.visible = false

# グリッドクリック処理（工場設計用）
func handle_grid_click(click_position: Vector2):
	# クリック位置をhex座標に変換
	var target_hex = get_hex_at_mouse_position(click_position)
	print("Grid clicked at %s, hex (%d, %d)" % [click_position, target_hex.q, target_hex.r])
	
	# 境界チェック
	if grid_display and not grid_display.is_within_bounds(target_hex):
		print("Target hex (%d, %d) is outside grid boundaries." % [target_hex.q, target_hex.r])
		return
	
	var piece_data = {}
	if palette_ui:
		piece_data = palette_ui.get_active_piece_data()
	if piece_data.is_empty():
		highlight_selected_hex(target_hex)
		return
	
	var shape: Array = piece_data.get("shape", [])
	if shape.is_empty():
		highlight_selected_hex(target_hex)
		return
	
	if GridManager.can_place(shape, target_hex):
		GridManager.place_piece(shape, target_hex)
		_render_piece(piece_data, target_hex)
	else:
		print("Cannot place piece at (%d, %d); space occupied or invalid." % [target_hex.q, target_hex.r])

# カメラ操作機能
func setup_camera():
	camera.position = Vector2.ZERO
	camera.zoom = Vector2(1.0, 1.0)

func zoom_camera(zoom_factor: float):
	var new_zoom = camera.zoom * zoom_factor
	# ズーム制限
	new_zoom.x = clamp(new_zoom.x, 0.3, 3.0)
	new_zoom.y = clamp(new_zoom.y, 0.3, 3.0)
	camera.zoom = new_zoom

func pan_camera(offset: Vector2):
	camera.position += offset * (1.0 / camera.zoom.x)

# 選択されたhexをハイライト表示
func highlight_selected_hex(hex_coord: Hex):
	if grid_display:
		# TODO: 単一hexハイライト機能を実装
		print("Selected hex (%d, %d) for factory placement" % [hex_coord.q, hex_coord.r])

func _render_piece(piece_data: Dictionary, base_hex: Hex):
	if not pieces_layer:
		return
	var piece_root = Node2D.new()
	piece_root.name = "PlacedPiece_%s_%d" % [piece_data.get("type", "Unknown"), pieces_layer.get_child_count()]
	pieces_layer.add_child(piece_root)
	
	var color: Color = piece_data.get("color", Color.WHITE)
	var shape: Array = piece_data.get("shape", [])
	for offset in shape:
		var target_hex = Hex.add(base_hex, offset)
		var hex_tile = HEX_TILE_SCENE.instantiate()
		if hex_tile is HexTile:
			hex_tile.setup_hex(target_hex)
			hex_tile.normal_color = color
			hex_tile.set_highlight(false)
		var sprite: Sprite2D = hex_tile.get_node_or_null("Sprite2D")
		if sprite:
			sprite.modulate = color
			sprite.z_index = 2
		hex_tile.position = grid_display.hex_to_pixel(target_hex)
		piece_root.add_child(hex_tile)

func get_preview_piece_data() -> Dictionary:
	if preview_piece_data.is_empty():
		_update_preview_piece()
	return preview_piece_data.duplicate(true)

func get_preview_cells() -> Array:
	return preview_cells.duplicate()

func update_preview_for_hex(target_hex: Hex):
	if not grid_display:
		return
	_update_preview_piece()
	if preview_piece_data.is_empty():
		preview_target_hex = null
		preview_cells.clear()
		_clear_preview_visuals()
		return
	if target_hex == null:
		preview_target_hex = null
		preview_cells.clear()
		_clear_preview_visuals()
		return
	if grid_display and not grid_display.is_within_bounds(target_hex):
		preview_target_hex = null
		preview_cells.clear()
		_clear_preview_visuals()
		return
	preview_target_hex = Hex.new(target_hex.q, target_hex.r, target_hex.s)
	preview_cells.clear()
	var shape: Array = preview_piece_data.get("shape", [])
	for offset in shape:
		var cell = Hex.add(preview_target_hex, offset)
		preview_cells.append(cell)
	_render_preview_visuals()

func place_preview_piece():
	if preview_piece_data.is_empty() or preview_target_hex == null:
		return
	var shape: Array = preview_piece_data.get("shape", [])
	if shape.is_empty():
		return
	if not GridManager.can_place(shape, preview_target_hex):
		return
	GridManager.place_piece(shape, preview_target_hex)
	_render_piece(preview_piece_data, preview_target_hex)
	_update_preview_for_current_mouse()

func _on_active_palette_slot_changed(new_index: int, _old_index: int):
	new_index = new_index # unused parameter placeholder
	_update_preview_piece()
	if preview_target_hex:
		update_preview_for_hex(preview_target_hex)
	else:
		_update_preview_for_current_mouse()

func _update_preview_piece():
	preview_piece_data = {}
	if not palette_ui:
		return
	var data = palette_ui.get_active_piece_data()
	if data.is_empty():
		return
	var shape: Array = data.get("shape", [])
	var shape_copy: Array = []
	for offset in shape:
		shape_copy.append(Hex.new(offset.q, offset.r, offset.s))
	preview_piece_data = {
		"type": data.get("type", null),
		"shape": shape_copy,
		"color": data.get("color", Color.WHITE)
	}

func _update_preview_for_current_mouse():
	if not grid_display:
		return
	if not is_inside_tree():
		return
	var mouse_pos = get_global_mouse_position()
	var hex = get_hex_at_mouse_position(mouse_pos)
	update_preview_for_hex(hex)

func _ensure_preview_root() -> Node2D:
	if not preview_layer:
		return null
	if preview_root and is_instance_valid(preview_root):
		return preview_root
	preview_root = Node2D.new()
	preview_root.name = "PreviewPiece"
	preview_layer.add_child(preview_root)
	return preview_root

func _clear_preview_visuals():
	var root = _ensure_preview_root()
	if not root:
		return
	for child in root.get_children():
		child.queue_free()

func _render_preview_visuals():
	var root = _ensure_preview_root()
	if not root or not grid_display:
		return
	_clear_preview_visuals()
	if preview_cells.is_empty():
		return
	var color: Color = preview_piece_data.get("color", Color.WHITE)
	var preview_color = Color(color.r, color.g, color.b, PREVIEW_ALPHA)
	for cell in preview_cells:
		var hex_tile = HEX_TILE_SCENE.instantiate()
		if hex_tile is HexTile:
			hex_tile.setup_hex(cell)
			hex_tile.normal_color = preview_color
			hex_tile.set_highlight(false)
		var sprite: Sprite2D = hex_tile.get_node_or_null("Sprite2D")
		if sprite:
			sprite.modulate = preview_color
			sprite.z_index = 3
		hex_tile.position = grid_display.hex_to_pixel(cell)
		root.add_child(hex_tile)
