class_name PiecePlacer
extends Node2D

const HexTileScene = preload("res://scenes/components/hex_tile/hex_tile.tscn")

# 依存関係（Mainから注入される）
var grid_manager

# 内部状態
var current_piece_shape: Array[Hex] = []
var current_rotation: int = 0
var current_hovered_hex: Hex
var mouse_preview_container: Node2D
var ghost_preview_container: Node2D

# 選択中のピースデータ
var selected_piece_data: PieceData


func setup(grid_manager_ref, mouse_container_ref: Node2D, ghost_container_ref: Node2D):
	grid_manager = grid_manager_ref
	mouse_preview_container = mouse_container_ref
	ghost_preview_container = ghost_container_ref


func select_piece(data: PieceData):
	selected_piece_data = data
	current_rotation = 0
	if selected_piece_data:
		current_piece_shape = selected_piece_data.shape.duplicate()
	else:
		current_piece_shape = []
	_draw_preview()


func _draw_preview():
	_clear_preview()

	if current_piece_shape.is_empty() or not selected_piece_data:
		return

	if not grid_manager or not mouse_preview_container or not ghost_preview_container:
		return

	var color = selected_piece_data.color

	for hex_coord in current_piece_shape:
		var pos = grid_manager.hex_to_pixel(hex_coord)

		# カーソル用タイル (手持ち)
		var cursor_tile = HexTileScene.instantiate()
		mouse_preview_container.add_child(cursor_tile)
		cursor_tile.position = pos
		cursor_tile.setup_hex(hex_coord)
		cursor_tile.set_color(color)
		cursor_tile.set_transparency(1.0)

		# ゴースト用タイル (スナップ)
		var ghost_tile = HexTileScene.instantiate()
		ghost_preview_container.add_child(ghost_tile)
		ghost_tile.position = pos
		ghost_tile.setup_hex(hex_coord)
		ghost_tile.set_color(Color.GHOST_WHITE)
		ghost_tile.set_transparency(0.5)


func _clear_preview():
	if mouse_preview_container:
		for child in mouse_preview_container.get_children():
			child.queue_free()
	if ghost_preview_container:
		for child in ghost_preview_container.get_children():
			child.queue_free()


func update_hover(local_mouse_pos: Vector2):
	var hex_coord = Layout.pixel_to_hex_rounded(grid_manager.layout, local_mouse_pos)
	current_hovered_hex = hex_coord

	var snapped_pos = Layout.hex_to_pixel(grid_manager.layout, hex_coord)

	# コンテナの位置を更新
	mouse_preview_container.position = local_mouse_pos
	ghost_preview_container.position = snapped_pos


func place_current_piece() -> bool:
	if current_hovered_hex == null:
		return false
	return _place_piece_at(current_hovered_hex)


# テストや外部から座標指定で配置する場合用
func place_piece_at_hex(target_hex: Hex) -> bool:
	return _place_piece_at(target_hex)


func _place_piece_at(target_hex: Hex) -> bool:
	if current_piece_shape.is_empty() or not selected_piece_data:
		return false

	if grid_manager.can_place(current_piece_shape, target_hex):
		grid_manager.place_piece(
			current_piece_shape, target_hex, selected_piece_data, current_rotation
		)
		return true

	return false


func rotate_current_piece():
	if current_piece_shape.is_empty():
		return

	current_rotation = (current_rotation + 1) % 6
	current_piece_shape = _get_rotated_piece_shape(current_piece_shape)
	_draw_preview()


# 指定した座標にあるピースを削除する
func remove_piece_at_hex(target_hex: Hex) -> bool:
	if grid_manager.remove_piece_at(target_hex):
		return true
	return false


func _get_rotated_piece_shape(original_shape: Array[Hex]) -> Array[Hex]:
	var rotated_shape: Array[Hex] = []
	for hex_offset in original_shape:
		rotated_shape.append(Hex.rotate_right(hex_offset))
	return rotated_shape
