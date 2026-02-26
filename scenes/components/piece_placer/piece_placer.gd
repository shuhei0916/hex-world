class_name PiecePlacer
extends Node2D

# ユーザーがいま何を、どの向きで、どこに置こうとしているか」というUI操作のステートマシン

const HexTileScene = preload("res://scenes/components/hex_tile/hex_tile.tscn")

# 依存関係（Mainから注入される）
var island

# 内部状態
var current_piece_shape: Array[Hex] = []
var current_rotation: int = 0
var current_hovered_hex: Hex

# 選択中のピースデータ
var selected_piece_data: PieceData

@onready var cursor_preview: Node2D = $CursorPreview
@onready var snap_preview: Node2D = $SnapPreview


func setup(island_ref):
	island = island_ref


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

	if not island or not cursor_preview or not snap_preview:
		return

	var color = selected_piece_data.color

	for hex_coord in current_piece_shape:
		var pos = island.hex_to_pixel(hex_coord)

		# カーソル用タイル (手持ち)
		var cursor_tile = HexTileScene.instantiate()
		cursor_preview.add_child(cursor_tile)
		cursor_tile.position = pos
		cursor_tile.setup_hex(hex_coord)
		cursor_tile.set_color(color)
		cursor_tile.set_transparency(1.0)

		# ゴースト用タイル (スナップ)
		var ghost_tile = HexTileScene.instantiate()
		snap_preview.add_child(ghost_tile)
		ghost_tile.position = pos
		ghost_tile.setup_hex(hex_coord)
		ghost_tile.set_color(Color.GHOST_WHITE)
		ghost_tile.set_transparency(0.5)


func _clear_preview():
	if cursor_preview:
		for child in cursor_preview.get_children():
			child.queue_free()
	if snap_preview:
		for child in snap_preview.get_children():
			child.queue_free()


func update_hover(local_mouse_pos: Vector2):
	var hex_coord = Layout.pixel_to_hex_rounded(island.layout, local_mouse_pos)
	current_hovered_hex = hex_coord

	var snapped_pos = Layout.hex_to_pixel(island.layout, hex_coord)

	# コンテナの位置を更新
	cursor_preview.position = local_mouse_pos
	snap_preview.position = snapped_pos


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

	if island.can_place(current_piece_shape, target_hex):
		island.place_piece(current_piece_shape, target_hex, selected_piece_data, current_rotation)
		return true

	return false


func rotate_current_piece():
	if current_piece_shape.is_empty():
		return

	current_rotation = (current_rotation + 1) % 6
	current_piece_shape = _get_rotated_piece_shape(current_piece_shape)
	_draw_preview()


func _get_rotated_piece_shape(original_shape: Array[Hex]) -> Array[Hex]:
	var rotated_shape: Array[Hex] = []
	for hex_offset in original_shape:
		rotated_shape.append(Hex.rotate_right(hex_offset))
	return rotated_shape
