class_name PiecePlacer
extends Node2D

# ユーザーがいま何を、どの向きで、どこに置こうとしているか」というUI操作のステートマシン

signal conveyor_path_extended
# 置ける場所なのに設置できなかった（在庫不足）。message は理由を示す文章
signal placement_denied(message: String)

const HexTileScene = preload("res://scenes/components/hex_tile/hex_tile.tscn")
const BELT_PREVIEW_TEXTURE = preload("res://scenes/components/piece/belt/forward_0.png")
const _BELT_TEXTURE_SIZE = 192.0
# キャラクターから何マス以内まで建築・撤去できるか
const REACH := 6
const OUT_OF_REACH_TEXT := "キャラクターから遠すぎて届かない"
const UNDER_PLAYER_TEXT := "キャラクターの足元には置けない"
# 届かない場所に合わせたゴーストの色
const OUT_OF_REACH_TINT := Color(1.0, 0.25, 0.25)

# 依存関係（Mainから注入される）
var chunk: Chunk
# キャラクターの立っているマス。ここから REACH マス以内だけ建築できる。null なら制限しない
var reach_center = null:
	set(value):
		if value == reach_center:
			return
		reach_center = value
		_refresh_reach_area()
# 建築できる範囲の表示。ピースを選んでいる間だけ出す
var reach_area := ReachArea.new()

# 内部状態
var current_piece_shape: Array[Vector2i] = []
var current_rotation: int = 0
# マウスが乗っているマス。マスの外なら null
var current_hovered_hex = null
var is_dragging: bool = false
var is_delete_dragging: bool = false
var selected_scene: PackedScene
var _last_drag_hex = null
var _selected_color: Color
var _is_conveyor: bool = false
var _selected_piece_type: int = -1
var _selected_port_direction: int = -1
var _selected_port_hex: Vector2i = Vector2i.ZERO
var _conveyor_drag_path: Array[Vector2i] = []
# コンベアのドラッグで、パスの先頭の直前にいたマス。無ければ null
var _drag_origin_hex = null

@onready var cursor_preview: Node2D = $CursorPreview
@onready var snap_preview: Node2D = $SnapPreview


func _ready() -> void:
	reach_area.visible = false
	add_child(reach_area)
	# ゴーストより奥に描く
	move_child(reach_area, 0)


func start_drag():
	is_dragging = true
	_last_drag_hex = null
	_drag_origin_hex = null
	_conveyor_drag_path.clear()


func stop_drag():
	is_dragging = false
	_last_drag_hex = null
	if _is_conveyor and not _conveyor_drag_path.is_empty():
		_place_conveyor_chain(current_hovered_hex)
	_conveyor_drag_path.clear()
	# パスプレビューで ZERO に移動した snap_preview をホバー位置へ戻してから描き直す
	# （戻さないとゴーストがチャンク中央に一瞬表示される）
	if current_hovered_hex != null:
		snap_preview.position = Layout.hex_to_pixel(chunk.layout, current_hovered_hex)
	_draw_preview()


func start_delete_drag():
	is_delete_dragging = true
	if current_hovered_hex != null:
		_remove_piece_at(current_hovered_hex)


func stop_delete_drag():
	is_delete_dragging = false


func setup(chunk_ref: Chunk):
	chunk = chunk_ref
	_refresh_reach_area()


# ピースを選んでいれば、今の chunk でキャラクターから届くマスを示す
func _refresh_reach_area() -> void:
	reach_area.visible = selected_scene != null and reach_center != null and chunk != null
	if not reach_area.visible:
		return
	reach_area.layout = chunk.layout
	reach_area.show_hexes(chunk.get_all_hexes().filter(func(hex): return _is_within_reach([hex])))


func select_piece(scene: PackedScene):
	selected_scene = scene
	current_rotation = 0
	if selected_scene:
		var piece = selected_scene.instantiate()
		current_piece_shape = piece.get_hex_shape()
		_selected_color = piece.piece_color
		_is_conveyor = (piece.piece_type == PieceData.Type.CONVEYOR)
		_selected_piece_type = piece.piece_type
		_selected_port_direction = piece.port_direction
		_selected_port_hex = piece.port_hex
		piece.free()
	else:
		current_piece_shape = []
	_draw_preview()
	_refresh_reach_area()


func _draw_preview():
	_clear_preview()

	if current_piece_shape.is_empty() or not selected_scene:
		return

	if not chunk or not cursor_preview or not snap_preview:
		return

	# カーソル用 (手持ち)。施設は置いたときと同じ本体の形で、コンベアはベルト画像で描く
	if not _is_conveyor:
		var body := PieceBody.new()
		cursor_preview.add_child(body)
		body.setup(current_piece_shape, _selected_color)
	for hex_coord in current_piece_shape:
		if _is_conveyor:
			_add_belt_preview(hex_coord)
		# ゴースト用タイル (スナップ)
		_add_ghost_tile(hex_coord)

	var ports = _get_current_output_ports()
	if not ports.is_empty():
		cursor_preview.add_child(Piece.make_output_arrow(ports[0]))


# コンベアのカーソルプレビュー: forward ベルト画像を出力方向へ向けて配置する（半透明）。
func _add_belt_preview(hex_coord: Vector2i):
	var direction = _selected_port_direction
	if _selected_port_direction >= 0:
		direction = (_selected_port_direction - current_rotation + 6) % 6
	var travel = Layout.hex_to_pixel(chunk.layout, Hex.DIRECTIONS[direction])
	var sprite = Sprite2D.new()
	sprite.texture = BELT_PREVIEW_TEXTURE
	sprite.position = Layout.hex_to_pixel(chunk.layout, hex_coord)
	# テクスチャの矢印は上(-Y)向き。-Y を進行方向へ向ける。
	sprite.rotation = travel.angle() + PI / 2.0
	sprite.scale = Vector2(
		ConveyorVisuals.BELT_WIDTH / _BELT_TEXTURE_SIZE, travel.length() / _BELT_TEXTURE_SIZE
	)
	sprite.modulate.a = 0.7
	cursor_preview.add_child(sprite)


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
		_remove_piece_at(hex_coord)

	var snapped_pos = Layout.hex_to_pixel(chunk.layout, hex_coord)

	cursor_preview.position = local_mouse_pos
	var reachable = _is_within_reach(_shape_at(hex_coord))
	snap_preview.modulate = Color.WHITE if reachable else OUT_OF_REACH_TINT
	cursor_preview.modulate = snap_preview.modulate

	if is_dragging and (_last_drag_hex == null or hex_coord != _last_drag_hex):
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
func place_piece_at_hex(target_hex: Vector2i) -> bool:
	return _place_piece_at(target_hex)


func _place_piece_at(target_hex: Vector2i) -> bool:
	if current_piece_shape.is_empty() or not selected_scene:
		return false
	if _is_conveyor and is_dragging:
		return _add_to_conveyor_path(target_hex)
	# 置けない場所なら何も言わず、置ける場所なのに届かないときだけ理由を伝える
	if (
		not chunk.can_place(current_piece_shape, target_hex, _selected_piece_type)
		or not _is_reachable_spot(_shape_at(target_hex))
	):
		return false
	# 置ける場所だと分かってから支払う（置けないのに在庫だけ減るのを防ぐ）
	var cost = BuildCost.of_scene(selected_scene)
	if not HubGoals.can_afford(cost):
		placement_denied.emit(BuildCost.shortage_text(cost))
		return false
	if HubGoals.pay(cost):
		var rotation := current_rotation
		if _is_conveyor:
			var fallback_dir := (_selected_port_direction - current_rotation + 6) % 6
			var optimal_dir := _compute_optimal_conveyor_direction(target_hex, fallback_dir)
			rotation = (_selected_port_direction - optimal_dir + 6) % 6
		chunk.place_piece(selected_scene, target_hex, rotation)
		return true
	return false


# いま選んでいるピースを base_hex に置いたときに占めるマス
func _shape_at(base_hex: Vector2i) -> Array[Vector2i]:
	var hexes: Array[Vector2i] = []
	for offset in current_piece_shape:
		hexes.append(base_hex + offset)
	return hexes


# hexes のすべてがキャラクターから REACH マス以内か（届く範囲を決めていなければ常に true）
func _is_within_reach(hexes: Array[Vector2i]) -> bool:
	if reach_center == null:
		return true
	for hex in hexes:
		if Hex.distance(hex, reach_center) > REACH:
			return false
	return true


# キャラクターの届く範囲にあって、足元をふさがない置き場所か。だめなら（ドラッグ中でなければ）理由を伝える
func _is_reachable_spot(hexes: Array[Vector2i]) -> bool:
	var reason := ""
	if not _is_within_reach(hexes):
		reason = OUT_OF_REACH_TEXT
	elif _covers_player(hexes):
		reason = UNDER_PLAYER_TEXT
	if reason != "" and not is_dragging:
		placement_denied.emit(reason)
	return reason == ""


# 上を歩けないピースが、キャラクターの足元のマスにかかるか
func _covers_player(hexes: Array[Vector2i]) -> bool:
	if reach_center == null or _selected_piece_type in PlayerCharacter.WALKABLE_PIECES:
		return false
	return reach_center in hexes


# いま選んでいるピースの設置コストを在庫から支払えるか
func can_afford_selected() -> bool:
	return HubGoals.can_afford(BuildCost.of_scene(selected_scene))


# プレイヤーの操作による撤去。設置コストは全額戻す。
func _remove_piece_at(hex: Vector2i) -> void:
	if not _is_within_reach([hex]):
		return
	var piece = chunk.get_piece_at_hex(hex)
	if piece == null:
		return
	var cost = BuildCost.of_piece(piece)
	if chunk.remove_piece_at(hex):
		HubGoals.refund(cost)


func _add_to_conveyor_path(hex: Vector2i) -> bool:
	for h in _conveyor_drag_path:
		if h == hex:
			return false
	if not chunk.can_place(current_piece_shape, hex) and not _is_replaceable_conveyor(hex):
		return false
	if not _is_within_reach([hex]):
		return false
	if _conveyor_drag_path.is_empty():
		# パスに入る直前にいたマス（施設の排出口からドラッグを始めたときの、その排出口）
		_drag_origin_hex = _last_drag_hex
	_conveyor_drag_path.append(hex)
	conveyor_path_extended.emit()
	return true


func _is_replaceable_conveyor(hex: Vector2i) -> bool:
	var existing = chunk.get_piece_at_hex(hex)
	return existing != null and existing.is_replaceable()


func _add_ghost_tile(hex: Vector2i):
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


func _place_conveyor_chain(end_target = null):
	var last_hex := _conveyor_drag_path[_conveyor_drag_path.size() - 1]
	var target_is_occupied: bool = (
		end_target != null and end_target != last_hex and chunk.is_occupied(end_target)
	)

	for i in range(_conveyor_drag_path.size()):
		var hex = _conveyor_drag_path[i]
		var can_place := chunk.can_place(current_piece_shape, hex)
		var can_replace := _is_replaceable_conveyor(hex)
		if not can_place and not can_replace:
			continue
		var direction: int
		if i < _conveyor_drag_path.size() - 1:
			direction = Hex.get_direction_to(hex, _conveyor_drag_path[i + 1])
		elif target_is_occupied:
			direction = Hex.get_direction_to(hex, end_target)
		elif i > 0:
			direction = Hex.get_direction_to(_conveyor_drag_path[i - 1], hex)
		else:
			# 1マスだけのときは進行方向がないので、手持ちの向きで置く
			direction = (_selected_port_direction - current_rotation + 6) % 6
		var rotation = (_selected_port_direction - direction + 6) % 6
		# 2マス目以降はパス上の1つ前から受け取る（先頭で曲がる分岐も入力側で接続を保つため）
		# 始点の既存コンベアは元の入力方向を引き継ぐ（分岐元から引いた分岐でも上流との接続を保つため）
		# 施設の排出口から引き始めた先頭は、その排出口の側から受け取る（真後ろのラインから分岐しないため）
		var input_direction := -1
		if i > 0:
			input_direction = Hex.get_direction_to(hex, _conveyor_drag_path[i - 1])
		elif can_replace:
			input_direction = chunk.get_piece_at_hex(hex).input_direction
		else:
			input_direction = _input_from_drag_origin(hex)
		if can_replace:
			chunk.remove_piece_at(hex)
		chunk.place_piece(selected_scene, hex, rotation, input_direction)


# ドラッグを施設の排出口のマスから始めたとき、先頭のベルト first_hex はその排出口の側から受け取る。
# そうでなければ -1（未指定）
func _input_from_drag_origin(first_hex: Vector2i) -> int:
	if _drag_origin_hex == null:
		return -1
	var origin = chunk.get_piece_at_hex(_drag_origin_hex)
	if origin == null:
		return -1
	var base = chunk.get_base_hex(origin)
	for port in origin.get_output_ports():
		var port_hex = base + port.hex
		if port_hex == _drag_origin_hex and Hex.neighbor(port_hex, port.direction) == first_hex:
			return Hex.get_direction_to(first_hex, port_hex)
	return -1


func _compute_optimal_conveyor_direction(hex: Vector2i, fallback_direction: int) -> int:
	var feeding_direction := -1
	for direction in range(6):
		var neighbor = chunk.get_piece_at_hex(Hex.neighbor(hex, direction))
		if neighbor == null:
			continue
		var base = chunk.get_base_hex(neighbor)
		for port in neighbor.get_output_ports():
			var abs_port = base + port.hex
			var target = Hex.neighbor(abs_port, port.direction)
			if target == hex:
				if feeding_direction != -1:
					return fallback_direction  # 複数の入力が競合 → fallback
				feeding_direction = direction
	if feeding_direction == -1:
		return fallback_direction
	return (feeding_direction + 3) % 6


func rotate_current_piece():
	if current_piece_shape.is_empty():
		return

	current_rotation = (current_rotation + 1) % 6
	current_piece_shape = _get_rotated_piece_shape(current_piece_shape)
	_draw_preview()


func _get_rotated_piece_shape(original_shape: Array[Vector2i]) -> Array[Vector2i]:
	var rotated_shape: Array[Vector2i] = []
	for hex_offset in original_shape:
		rotated_shape.append(Hex.rotate_right(hex_offset))
	return rotated_shape
