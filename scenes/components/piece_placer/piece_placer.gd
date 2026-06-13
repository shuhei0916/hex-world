class_name PiecePlacer
extends Node2D

# ユーザーがいま何を、どの向きで、どこに置こうとしているか」というUI操作のステートマシン

signal conveyor_path_extended

const HexTileScene = preload("res://scenes/components/hex_tile/hex_tile.tscn")

# 依存関係（Mainから注入される）
var chunk: Chunk

# 内部状態
var current_piece_shape: Array[Hex] = []
var current_rotation: int = 0
var current_hovered_hex: Hex
var is_dragging: bool = false
var is_delete_dragging: bool = false
var selected_scene: PackedScene
var _last_drag_hex: Hex = null
var _selected_color: Color
var _is_conveyor: bool = false
var _selected_port_direction: int = -1
var _selected_port_hex: Vector2i = Vector2i.ZERO
var _conveyor_drag_path: Array[Hex] = []

@onready var cursor_preview: Node2D = $CursorPreview
@onready var snap_preview: Node2D = $SnapPreview


func start_drag():
	is_dragging = true
	_last_drag_hex = null
	_conveyor_drag_path.clear()


func stop_drag():
	is_dragging = false
	_last_drag_hex = null
	if _is_conveyor and not _conveyor_drag_path.is_empty():
		_place_conveyor_chain()
	_conveyor_drag_path.clear()
	# パスプレビューで ZERO に移動した snap_preview をホバー位置へ戻してから描き直す
	# （戻さないとゴーストがチャンク中央に一瞬表示される）
	if current_hovered_hex != null:
		snap_preview.position = Layout.hex_to_pixel(chunk.layout, current_hovered_hex)
	_draw_preview()


func start_delete_drag():
	is_delete_dragging = true
	if current_hovered_hex != null:
		chunk.remove_piece_at(current_hovered_hex)


func stop_delete_drag():
	is_delete_dragging = false


func setup(chunk_ref: Chunk):
	chunk = chunk_ref


func select_piece(scene: PackedScene):
	selected_scene = scene
	current_rotation = 0
	if selected_scene:
		var piece = selected_scene.instantiate()
		current_piece_shape = piece.get_hex_shape()
		_selected_color = piece.piece_color
		_is_conveyor = (piece.piece_type == PieceData.Type.CONVEYOR)
		_selected_port_direction = piece.port_direction
		_selected_port_hex = piece.port_hex
		piece.free()
	else:
		current_piece_shape = []
	_draw_preview()


func _draw_preview():
	_clear_preview()

	if current_piece_shape.is_empty() or not selected_scene:
		return

	if not chunk or not cursor_preview or not snap_preview:
		return

	var color = _selected_color

	for hex_coord in current_piece_shape:
		# カーソル用タイル (手持ち)
		var cursor_tile = HexTileScene.instantiate()
		cursor_preview.add_child(cursor_tile)
		cursor_tile.position = Layout.hex_to_pixel(chunk.layout, hex_coord)
		cursor_tile.setup_hex(hex_coord)
		cursor_tile.set_color(color)
		cursor_tile.set_transparency(1.0)

		# ゴースト用タイル (スナップ)
		_add_ghost_tile(hex_coord)

	var ports = _get_current_output_ports()
	if not ports.is_empty():
		cursor_preview.add_child(Piece.make_output_arrow(ports[0]))


func _get_current_output_ports() -> Array:
	if _selected_port_direction < 0:
		return []
	var hex = Hex.from_offset_rotated(_selected_port_hex, current_rotation)
	var direction = (_selected_port_direction - current_rotation + 6) % 6
	return [{"hex": hex, "direction": direction}]


func _clear_preview():
	if cursor_preview:
		for child in cursor_preview.get_children():
			child.free()
	if snap_preview:
		for child in snap_preview.get_children():
			child.free()


func update_hover(local_mouse_pos: Vector2):
	var hex_coord = Layout.pixel_to_hex_rounded(chunk.layout, local_mouse_pos)
	current_hovered_hex = hex_coord

	if is_delete_dragging:
		chunk.remove_piece_at(hex_coord)

	var snapped_pos = Layout.hex_to_pixel(chunk.layout, hex_coord)

	cursor_preview.position = local_mouse_pos

	if is_dragging and (_last_drag_hex == null or not Hex.equals(hex_coord, _last_drag_hex)):
		_place_piece_at(hex_coord)
		_last_drag_hex = hex_coord

	if _is_conveyor and is_dragging and not _conveyor_drag_path.is_empty():
		_update_conveyor_path_preview()
	else:
		snap_preview.position = snapped_pos


func place_current_piece() -> bool:
	if current_hovered_hex == null:
		return false
	return _place_piece_at(current_hovered_hex)


# テストや外部から座標指定で配置する場合用
func place_piece_at_hex(target_hex: Hex) -> bool:
	return _place_piece_at(target_hex)


func _place_piece_at(target_hex: Hex) -> bool:
	if current_piece_shape.is_empty() or not selected_scene:
		return false
	if _is_conveyor and is_dragging:
		return _add_to_conveyor_path(target_hex)
	if chunk.can_place(current_piece_shape, target_hex):
		chunk.place_piece(selected_scene, target_hex, current_rotation)
		return true
	return false


func _add_to_conveyor_path(hex: Hex) -> bool:
	for h in _conveyor_drag_path:
		if Hex.equals(h, hex):
			return false
	if not chunk.can_place(current_piece_shape, hex):
		return false
	_conveyor_drag_path.append(hex)
	conveyor_path_extended.emit()
	return true


func _add_ghost_tile(hex: Hex):
	var ghost_tile = HexTileScene.instantiate()
	snap_preview.add_child(ghost_tile)
	ghost_tile.position = Layout.hex_to_pixel(chunk.layout, hex)
	ghost_tile.setup_hex(hex)
	ghost_tile.set_color(Color.GHOST_WHITE)
	ghost_tile.set_transparency(0.5)


func _update_conveyor_path_preview():
	for child in snap_preview.get_children():
		child.free()
	snap_preview.position = Vector2.ZERO
	for hex in _conveyor_drag_path:
		_add_ghost_tile(hex)


func _place_conveyor_chain():
	if _conveyor_drag_path.size() == 1:
		chunk.place_piece(selected_scene, _conveyor_drag_path[0], current_rotation)
		return
	for i in range(_conveyor_drag_path.size()):
		var hex = _conveyor_drag_path[i]
		if not chunk.can_place(current_piece_shape, hex):
			continue
		var direction: int
		if i < _conveyor_drag_path.size() - 1:
			direction = Hex.get_direction_to(hex, _conveyor_drag_path[i + 1])
		else:
			direction = Hex.get_direction_to(_conveyor_drag_path[i - 1], hex)
		var rotation = (_selected_port_direction - direction + 6) % 6
		chunk.place_piece(selected_scene, hex, rotation)


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
