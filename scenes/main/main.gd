class_name Main
extends Node2D

const PaletteScript = preload("res://scenes/ui/palette/palette.gd")
const HexTileScene = preload("res://scenes/components/hex_tile/hex_tile.tscn")

@onready var hud: HUD = $HUD
@onready var grid_manager:= $GridManager
@onready var preview_layer = $PreviewLayer
@onready var current_piece_preview = $PreviewLayer/CurrentPiecePreview

var palette: Palette
var current_hovered_hex: Hex 
var current_piece_shape: Array[Hex] = [] # 現在のプレビューピースの形状（回転適用済み）

func _init():
	palette = PaletteScript.new()

func _ready():
	grid_manager.create_hex_grid(grid_manager.grid_radius)
	
	hud.setup_ui(palette)
	
	palette.active_slot_changed.connect(_on_active_slot_changed)
	_update_preview(palette.get_active_index())

func _unhandled_input(event):
	_handle_key_input(event)
	_handle_mouse_motion(event)
	_handle_mouse_click(event)

func _handle_key_input(event):
	if event is InputEventKey and event.pressed and not event.is_echo():
		if event.keycode >= KEY_1 and event.keycode <= KEY_9:
			var index = event.keycode - KEY_1
			palette.select_slot(index)
		elif event.keycode == KEY_R:
			rotate_current_piece()

func _handle_mouse_motion(event):
	if event is InputEventMouseMotion:
		if current_piece_preview:
			var local_mouse_pos = make_input_local(event).position
			var hex_coord = Layout.pixel_to_hex_rounded(grid_manager.layout, local_mouse_pos)
			current_hovered_hex = hex_coord # current_hovered_hexを更新
			
			var snapped_pos = Layout.hex_to_pixel(grid_manager.layout, hex_coord)
			current_piece_preview.position = snapped_pos

func _handle_mouse_click(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		# 左クリックでピースを配置
		if current_hovered_hex != null: # ホバーしているHexがあれば配置を試みる
			place_selected_piece(current_hovered_hex)

func _on_active_slot_changed(new_index: int, _old_index: int):
	_update_preview(new_index)

func _update_preview(slot_index: int):
	var piece_data = palette.get_piece_data_for_slot(slot_index)
	if piece_data.is_empty():
		current_piece_shape = []
		_clear_preview()
		return
	
	# 形状を初期化（パレットからコピー）
	current_piece_shape = piece_data["shape"].duplicate()
	_draw_preview()

# 現在の形状に基づいてプレビューを描画
func _draw_preview():
	_clear_preview()
	
	if current_piece_shape.is_empty():
		return

	var piece_data = palette.get_piece_data_for_slot(palette.get_active_index())
	var color = piece_data["color"] # 色はパレットから取得（回転しても色は変わらない）
	
	for hex_coord in current_piece_shape:
		var hex_tile = HexTileScene.instantiate()
		current_piece_preview.add_child(hex_tile)
		
		var pos = grid_manager.hex_to_pixel(hex_coord)
		hex_tile.position = pos
		hex_tile.setup_hex(hex_coord)
		
		# 色と透過度を設定
		hex_tile.set_color(color)
		hex_tile.set_transparency(0.5)

# プレビューをクリア
func _clear_preview():
	for child in current_piece_preview.get_children():
		child.queue_free()

# 新しいメソッド：選択中のピースを指定したHex座標に配置する
func place_selected_piece(target_hex: Hex) -> bool:
	if current_piece_shape.is_empty():
		return false
	
	var selected_piece_data = palette.get_piece_data_for_slot(palette.get_active_index())
	var color = selected_piece_data["color"] # ピースの色を取得
	
	# shapeはcurrent_piece_shapeを使う（回転が反映されている）
	if grid_manager.can_place(current_piece_shape, target_hex):
		grid_manager.place_piece(current_piece_shape, target_hex, color) 
		print("piece has been placed at ", target_hex.to_string())
		# TODO: 配置されたピースを画面に表示する
		return true
	else:
		print("piece cannot be placed at ", target_hex.to_string())
		return false

# 新しいメソッド：現在のプレビューピースを回転させる
func _get_rotated_piece_shape(original_shape: Array[Hex]) -> Array[Hex]:
	var rotated_shape: Array[Hex] = []
	for hex_offset in original_shape:
		rotated_shape.append(Hex.rotate_right(hex_offset))
	return rotated_shape

func rotate_current_piece():
	if current_piece_shape.is_empty():
		return
	
	current_piece_shape = _get_rotated_piece_shape(current_piece_shape)
	_draw_preview()
