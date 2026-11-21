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
const NO_ROOM_TO_PUSH_TEXT := "キャラクターを押し出せる場所がない"
const OCCUPIED_TEXT := "ほかの設置物と重なっている"
const OUTSIDE_TEXT := "chunk の外には置けない"
const BRIDGE_EDGE_TEXT := "橋は chunk の辺にしか置けない"
# 届かない・置けない場所に合わせたゴーストの色
const DENIED_TINT := Color(1.0, 0.25, 0.25)

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
# 上を歩けないピースを置く前に、置くマス（Array[Vector2i]）に重なるキャラクターを押し出す処理。
# 押し出す必要が無いか押し出せたら true を返す。未設定なら押し出さない（Main から注入される）
var push_player := Callable()

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
# true の間はクリックした1回の設置。置けなければ理由を伝える（ドラッグでなぞったマスでは伝えない）
var _is_click := false
# コンベアのドラッグを押し始めたマス。何も引けずに離したとき、そこに置けなかった理由を伝える
var _conveyor_press_hex = null

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
	_conveyor_press_hex = null
	_conveyor_drag_path.clear()


func stop_drag():
	is_dragging = false
	_last_drag_hex = null
	if _is_conveyor and not _conveyor_drag_path.is_empty():
		_place_conveyor_chain(current_hovered_hex)
	elif _is_conveyor and _conveyor_press_hex != null:
		# 施設の上で押してもそこから引き出すかもしれないので、何も引けずに離したときだけ伝える
		_deny(_conveyor_denial_reason(_conveyor_press_hex))
	_conveyor_press_hex = null
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
	snap_preview.modulate = Color.WHITE if _looks_placeable(hex_coord) else DENIED_TINT
	cursor_preview.modulate = snap_preview.modulate

	if is_dragging and (_last_drag_hex == null or hex_coord != _last_drag_hex):
		_place_piece_at(hex_coord)
		_last_drag_hex = hex_coord

	if _is_conveyor and is_dragging and not _conveyor_drag_path.is_empty():
		_update_conveyor_path_preview()
	else:
		snap_preview.position = snapped_pos


# ゴーストを白く描くか。届かない場所は赤くする。施設は重なる・はみ出す場所も赤くするが、
# コンベアは施設の排出口から引き始めることがあるので、施設の上でも赤くしない
func _looks_placeable(base_hex: Vector2i) -> bool:
	if not _is_within_reach(_shape_at(base_hex)):
		return false
	if _is_conveyor or selected_scene == null:
		return true
	return _spot_denial_reason(base_hex) == ""


# クリックした1回の設置。置けなければ理由を伝える
func place_current_piece() -> bool:
	if current_hovered_hex == null:
		return false
	_is_click = true
	var placed := _place_piece_at(current_hovered_hex)
	_is_click = false
	if is_dragging:
		# 押したマスの中でマウスを動かしても、もう一度は置こうとしない
		if _is_conveyor and _conveyor_drag_path.is_empty():
			_conveyor_press_hex = current_hovered_hex
		_last_drag_hex = current_hovered_hex
	return placed


# テストや外部から座標指定で配置する場合用
func place_piece_at_hex(target_hex: Vector2i) -> bool:
	return _place_piece_at(target_hex)


func _place_piece_at(target_hex: Vector2i) -> bool:
	if current_piece_shape.is_empty() or not selected_scene:
		return false
	if _is_conveyor and is_dragging:
		return _add_to_conveyor_path(target_hex)
	var hexes := _shape_at(target_hex)
	# 置ける場所だと分かってから、押し出し・支払いをする（置けないのに在庫だけ減るのを防ぐ）
	var cost = BuildCost.of_scene(selected_scene)
	var reason := _spot_denial_reason(target_hex)
	if reason == "" and not HubGoals.can_afford(cost):
		reason = BuildCost.shortage_text(cost)
	if reason == "" and not _push_player_away(hexes):
		reason = NO_ROOM_TO_PUSH_TEXT
	if reason != "":
		_deny(reason)
		return false
	if HubGoals.pay(cost):
		var rotation := current_rotation
		var input_direction := -1
		if _is_conveyor:
			var fallback_dir := (_selected_port_direction - current_rotation + 6) % 6
			var orientation := _compute_conveyor_orientation(target_hex, fallback_dir)
			rotation = (_selected_port_direction - orientation[0] + 6) % 6
			input_direction = orientation[1]
		chunk.place_piece(selected_scene, target_hex, rotation, input_direction)
		_reorient_belts_around(hexes)
		return true
	return false


# 置けなかった理由を伝える。ドラッグでなぞったマスでは伝えない（なぞるたびに出ると煩い）
func _deny(reason: String) -> void:
	if reason != "" and (_is_click or not is_dragging):
		placement_denied.emit(reason)


# いま選んでいるピースを base_hex に置けない理由。置けるなら空
func _spot_denial_reason(base_hex: Vector2i) -> String:
	var hexes := _shape_at(base_hex)
	for hex in hexes:
		if not chunk.is_inside_grid(hex):
			return OUTSIDE_TEXT
	if not chunk.can_place(current_piece_shape, base_hex, _selected_piece_type):
		if hexes.any(func(hex): return chunk.is_occupied(hex)):
			return OCCUPIED_TEXT
		return BRIDGE_EDGE_TEXT
	if not _is_within_reach(hexes):
		return OUT_OF_REACH_TEXT
	return ""


# コンベアを hex に置けない理由（既にあるコンベアは置き換えられるので置ける）。置けるなら空
func _conveyor_denial_reason(hex: Vector2i) -> String:
	if _is_replaceable_conveyor(hex):
		return OUT_OF_REACH_TEXT if not _is_within_reach([hex]) else ""
	return _spot_denial_reason(hex)


# 上を歩けないピースを hexes に置く前に、重なるキャラクターを押し出す。置いてよければ true
func _push_player_away(hexes: Array[Vector2i]) -> bool:
	if not push_player.is_valid() or _selected_piece_type in PlayerCharacter.WALKABLE_PIECES:
		return true
	return push_player.call(hexes)


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
	var base = chunk.get_base_hex(piece)
	var hexes: Array[Vector2i] = []
	for offset in piece.get_hex_shape():
		hexes.append(base + offset)
	if chunk.remove_piece_at(hex):
		HubGoals.refund(cost)
		_reorient_belts_around(hexes)


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
	_reorient_belts_around(_conveyor_drag_path)


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
	return _compute_conveyor_orientation(hex, fallback_direction)[0]


# ---- コンベアの向きの自動調整（shapez の computeOptimalDirectionAndRotationVariantAtTile 相当）----


# hex にコンベアを1つ置くときの [出口の方向, 入力側（-1 は真後ろ）]。out は手持ちの向き。
# - 真後ろから入れてくる相手がいれば直進
# - 入れてくる相手が1つだけなら、出口はそのままで、その相手の側から受ける曲がり
#   （相手が正面にいるときは曲がれないので、相手から遠ざかる直進に反転する）
# - 入れてくる相手がいなければ、正面が空いていて横に受け取るベルトが1つだけあるとき、そちらへ曲がる
func _compute_conveyor_orientation(hex: Vector2i, out: int) -> Array:
	var back := (out + 3) % 6
	var feeders := _port_feeders(hex)
	if back in feeders or feeders.size() >= 2:
		return [out, -1]
	if feeders.size() == 1:
		var feeder: int = feeders[0]
		if feeder == out:
			return [back, -1]
		return [out, feeder]
	var turn := _turn_toward_taker(hex, out, back)
	if turn >= 0:
		return [turn, back]
	return [out, -1]


# hex へ出力ポートを向けている隣のピースの方向（0-5）
func _port_feeders(hex: Vector2i) -> Array:
	var directions := []
	for direction in range(6):
		var neighbor = chunk.get_piece_at_hex(Hex.neighbor(hex, direction))
		if neighbor == null or neighbor == chunk.get_piece_at_hex(hex):
			continue
		var base = chunk.get_base_hex(neighbor)
		for port in neighbor.get_output_ports():
			if Hex.neighbor(base + port.hex, port.direction) == hex:
				directions.append(direction)
				break
	return directions


# 正面（out）が空いていて、横（out・input 以外）に hex から受け取るベルトが1つだけあれば、その方向。
# なければ -1。ベルトは入力側でだけ受け取るので、入力側が hex を向いているベルトだけを数える
func _turn_toward_taker(hex: Vector2i, out: int, input: int) -> int:
	if chunk.get_piece_at_hex(Hex.neighbor(hex, out)) != null:
		return -1
	var takers := []
	for direction in range(6):
		if direction == out or direction == input:
			continue
		var neighbor = chunk.get_piece_at_hex(Hex.neighbor(hex, direction))
		if neighbor != null and neighbor.is_replaceable():
			if _belt_input_side(neighbor) == (direction + 3) % 6:
				takers.append(direction)
	return takers[0] if takers.size() == 1 else -1


# ベルトが受け取る側（入力側が未指定なら真後ろ）
func _belt_input_side(belt: Piece) -> int:
	if belt.input_direction >= 0:
		return belt.input_direction
	return (_belt_output(belt) + 3) % 6


func _belt_output(belt: Piece) -> int:
	return belt.get_output_ports()[0]["direction"]


# プレイヤーが hexes に置いた／撤去したあと、その周りのベルトの向きを直す
# （shapez の updateSurroundingBeltPlacement 相当）。セーブの読み込みなど、chunk に直接置くときは行わない
func _reorient_belts_around(hexes: Array) -> void:
	var visited := {}
	for hex in hexes:
		for direction in range(6):
			var neighbor_hex = Hex.neighbor(hex, direction)
			if neighbor_hex in hexes or visited.has(neighbor_hex):
				continue
			visited[neighbor_hex] = true
			var belt = chunk.get_piece_at_hex(neighbor_hex)
			if belt != null and belt.is_replaceable():
				_reorient_belt(neighbor_hex, belt)


# 置いてあるベルト1つの向き直し。いま受け取れているベルトの入力側は変えない。
# - 入力側に相手がいなくなっていて、入れてくる相手が（正面以外に）1つだけあれば、その側から受ける
# - 正面が空いていて、横に受け取るベルトが1つだけあれば、そちらへ曲がる
func _reorient_belt(hex: Vector2i, belt: Piece) -> void:
	var out := _belt_output(belt)
	var input := _belt_input_side(belt)
	var new_input: int = belt.input_direction
	if not input in chunk.get_feeding_directions(hex):
		var feeders = _port_feeders(hex).filter(func(d): return d != out)
		if feeders.size() == 1:
			input = feeders[0]
			new_input = input
	var new_out := out
	var turn := _turn_toward_taker(hex, out, input)
	if turn >= 0:
		new_out = turn
		new_input = input
	if new_out == out and new_input == belt.input_direction:
		return
	chunk.reorient_conveyor(hex, (belt.port_direction - new_out + 6) % 6, new_input)


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
