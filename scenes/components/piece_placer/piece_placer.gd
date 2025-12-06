class_name PiecePlacer
extends Node2D

const HexTileScene = preload("res://scenes/components/hex_tile/hex_tile.tscn")

# 依存関係（Mainから注入される）
var grid_manager
var palette: Palette

# 内部状態
var current_piece_shape: Array[Hex] = []
var current_hovered_hex: Hex
var preview_layer: Node2D
var current_piece_preview: Node2D

func setup(grid_manager_ref, palette_ref: Palette):
	grid_manager = grid_manager_ref
	palette = palette_ref
	
	# プレビュー用ノードのセットアップ
	preview_layer = Node2D.new()
	preview_layer.name = "PreviewLayer"
	add_child(preview_layer)
	
	current_piece_preview = Node2D.new()
	current_piece_preview.name = "CurrentPiecePreview"
	preview_layer.add_child(current_piece_preview)
	
	# パレットのシグナル接続
	palette.active_slot_changed.connect(_on_active_slot_changed)
	
	# 初期表示
	_update_preview(palette.get_active_index())

func _on_active_slot_changed(new_index: int, _old_index: int):
	_update_preview(new_index)

func _update_preview(slot_index: int):
	var piece_data = palette.get_piece_data_for_slot(slot_index)
	if piece_data.is_empty():
		current_piece_shape = []
		_clear_preview()
		return
	
	current_piece_shape = piece_data["shape"].duplicate()
	_draw_preview()

func _draw_preview():
	_clear_preview()
	
	if current_piece_shape.is_empty():
		return

	var piece_data = palette.get_piece_data_for_slot(palette.get_active_index())
	var color = piece_data["color"]
	
	for hex_coord in current_piece_shape:
		var hex_tile = HexTileScene.instantiate()
		current_piece_preview.add_child(hex_tile)
		
		var pos = grid_manager.hex_to_pixel(hex_coord)
		hex_tile.position = pos
		hex_tile.setup_hex(hex_coord)
		
		hex_tile.set_color(color)
		hex_tile.set_transparency(0.5)

func _clear_preview():
	for child in current_piece_preview.get_children():
		child.queue_free()

func update_hover(local_mouse_pos: Vector2):
	if current_piece_preview:
		var hex_coord = Layout.pixel_to_hex_rounded(grid_manager.layout, local_mouse_pos)
		current_hovered_hex = hex_coord
		
		var snapped_pos = Layout.hex_to_pixel(grid_manager.layout, hex_coord)
		current_piece_preview.position = snapped_pos

func place_current_piece() -> bool:
	if current_hovered_hex == null:
		return false
	return _place_piece_at(current_hovered_hex)

# テストや外部から座標指定で配置する場合用
func place_piece_at_hex(target_hex: Hex) -> bool:
	return _place_piece_at(target_hex)

func _place_piece_at(target_hex: Hex) -> bool:
	if current_piece_shape.is_empty():
		return false
	
	var selected_piece_data = palette.get_piece_data_for_slot(palette.get_active_index())
	var color = selected_piece_data["color"]
	
	if grid_manager.can_place(current_piece_shape, target_hex):
		grid_manager.place_piece(current_piece_shape, target_hex, color)
		print("piece has been placed at ", target_hex.to_string())
		return true
	else:
		print("piece cannot be placed at ", target_hex.to_string())
		return false

func rotate_current_piece():
	if current_piece_shape.is_empty():
		return
	
	current_piece_shape = _get_rotated_piece_shape(current_piece_shape)
	_draw_preview()

# 指定した座標にあるピースを削除する
func remove_piece_at_hex(target_hex: Hex) -> bool:
	if grid_manager.remove_piece_at(target_hex):
		print("piece removed at ", target_hex.to_string())
		return true
	return false

func _get_rotated_piece_shape(original_shape: Array[Hex]) -> Array[Hex]:
	var rotated_shape: Array[Hex] = []
	for hex_offset in original_shape:
		rotated_shape.append(Hex.rotate_right(hex_offset))
	return rotated_shape
