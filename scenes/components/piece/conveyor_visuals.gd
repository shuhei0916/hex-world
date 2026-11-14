class_name ConveyorVisuals
extends Node2D

const BELT_WIDTH = 40.0
# 地面(0)より手前、施設のタイル(10)より奥
const Z_INDEX := 6
const CURVE_SEGMENTS = 12

const _BELT_FILL := Color(0.77, 0.77, 0.77, 1.0)
const _BELT_EDGE := Color(0.54, 0.54, 0.57, 1.0)
const _BELT_ARROW := Color(0.62, 0.62, 0.62, 1.0)
# 1マス（入口の辺から出口の辺まで）に並べる矢印の本数。どのコンベアでも同じ本数にして、
# 隣のコンベアとの境目で矢印の間隔が変わらないようにする
const ARROWS_PER_PIECE := 2
const _ARROW_SIZE := 8.0

# 矢印のアニメーション用の時計。全コンベアで共有する（コンベアごとに持つと、設置した時刻の
# 違いで矢印の位置がずれ、つながって見えなくなる）。1フレームに1回だけ進める
static var _shared_clock: float = 0.0
static var _clock_frame: int = -1

var _path: PackedVector2Array = PackedVector2Array()
var _paths: Array[PackedVector2Array] = []  # 出力方向ごとの、主入力から出口までのパス
var _merge_paths: Array[PackedVector2Array] = []  # 主入力以外の入力（合流）の、辺から中心までのパス
var _output_directions: Array = []
var _input_direction: int = -1  # 主入力。出口へのパスはここから描く
var _merge_input_directions: Array = []

@onready var _piece: Piece = get_parent()
@onready var _mover: Node = _find_mover()
@onready var _item_icon: Sprite2D = $ItemIcon
@onready var _item_icon_2: Sprite2D = $ItemIcon2


static func sample_bezier(
	p0: Vector2, ctrl: Vector2, p2: Vector2, segments: int
) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in range(segments + 1):
		var t = float(i) / segments
		var mt = 1.0 - t
		pts.append(mt * mt * p0 + 2.0 * mt * t * ctrl + t * t * p2)
	return pts


# 時刻 clock における矢印の位置。1マスの経路の入口を0、出口を1とした割合で返す（小さい順）。
# 矢印は搬送時間ちょうどで1マスを通り抜けるので、出口を出た矢印が同時に次の入口に現れる。
static func arrow_fractions(clock: float) -> Array:
	var gap = 1.0 / ARROWS_PER_PIECE
	var traveled = clock * HubGoals.get_belt_speed() / TransferBuffer.TRANSFER_TIME
	var phase = fmod(traveled, gap)
	var fractions := []
	for i in ARROWS_PER_PIECE:
		fractions.append(phase + i * gap)
	return fractions


# path 上に矢印を置く位置と向き [{position, tangent}]。
# covered: path が1マスの経路のうち入口側からどこまでを占めるか（合流の辺→中心は 0.5）。
static func arrow_points(path: PackedVector2Array, fractions: Array, covered: float = 1.0) -> Array:
	var total := 0.0
	for i in range(path.size() - 1):
		total += (path[i + 1] - path[i]).length()
	var points := []
	if total < 1.0:
		return points
	for fraction in fractions:
		if fraction > covered:
			continue
		var target = fraction / covered * total
		var walked := 0.0
		for i in range(path.size() - 1):
			var segment = path[i + 1] - path[i]
			if target <= walked + segment.length() or i == path.size() - 2:
				var local_t = clampf((target - walked) / segment.length(), 0.0, 1.0)
				points.append(
					{
						"position": path[i].lerp(path[i + 1], local_t),
						"tangent": segment.normalized()
					}
				)
				break
			walked += segment.length()
	return points


func _ready():
	z_index = Z_INDEX
	z_as_relative = false
	_item_icon.z_index = 7
	_item_icon.z_as_relative = false
	_item_icon_2.z_index = 7
	_item_icon_2.z_as_relative = false
	_piece.shape_changed.connect(refresh_belt)
	refresh_belt()


func _find_mover() -> Node:
	for sibling in get_parent().get_children():
		if sibling.has_method("get_held_item"):
			return sibling
	return null


func _process(delta: float):
	var frame = Engine.get_process_frames()
	if frame != _clock_frame:
		_clock_frame = frame
		_shared_clock += delta
	queue_redraw()
	update_item_icon()


func set_input_direction(direction: int):
	set_input_directions([] if direction < 0 else [direction])


# 先頭を主入力、残りを合流してくる入力として描く
func set_input_directions(dirs: Array):
	_input_direction = dirs[0] if not dirs.is_empty() else -1
	_merge_input_directions = dirs.slice(1)
	refresh_belt()


func get_input_directions() -> Array:
	if _input_direction < 0:
		return []
	return [_input_direction] + _merge_input_directions


func set_output_directions(dirs: Array):
	_output_directions = dirs
	refresh_belt()


func refresh_belt():
	_paths = []
	_merge_paths = []
	var ports = _piece.get_output_ports()
	if ports.is_empty():
		return
	var layout = Layout.make_default()
	var primary_dir = ports[0]["direction"]
	var dirs = _output_directions if not _output_directions.is_empty() else [primary_dir]
	var input_dir = _input_direction if _input_direction >= 0 else (primary_dir + 3) % 6
	var in_edge = Layout.hex_to_pixel(layout, Hex.hex_directions[input_dir]) * 0.5
	for output_dir in dirs:
		var out_edge = Layout.hex_to_pixel(layout, Hex.hex_directions[output_dir]) * 0.5
		# 分岐は中心で行き先を決めるため、どの出口へも入口→中心の区間を共有する直線で描く
		if dirs.size() >= 2:
			_paths.append(PackedVector2Array([in_edge, Vector2.ZERO, out_edge]))
			continue
		var is_straight = (input_dir + 3) % 6 == output_dir
		var segs = 2 if is_straight else CURVE_SEGMENTS
		_paths.append(sample_bezier(in_edge, Vector2.ZERO, out_edge, segs))
	_path = _paths[0]
	# 合流: 主入力のパスは中心を通るので、辺から中心までの直線で継ぎ足せばつながって見える
	for merge_dir in _merge_input_directions:
		var merge_edge = Layout.hex_to_pixel(layout, Hex.hex_directions[merge_dir]) * 0.5
		_merge_paths.append(PackedVector2Array([merge_edge, Vector2.ZERO]))
	queue_redraw()


# いまの時刻での矢印の位置（1マスの経路に対する割合）
func current_arrow_fractions() -> Array:
	return arrow_fractions(_shared_clock)


func _draw():
	var fractions = current_arrow_fractions()
	for path in _merge_paths:
		_draw_belt(path, fractions, 0.5)
	for path in _paths:
		_draw_belt(path, fractions, 1.0)


func _draw_belt(path: PackedVector2Array, fractions: Array, covered: float) -> void:
	if path.size() < 2:
		return
	draw_polyline(path, _BELT_EDGE, BELT_WIDTH, true)
	draw_polyline(path, _BELT_FILL, BELT_WIDTH - 6.0, true)
	for point in arrow_points(path, fractions, covered):
		_draw_chevron(point["position"], point["tangent"])


func _draw_chevron(pos: Vector2, tangent: Vector2):
	var polygon = chevron_polygon(pos, tangent)
	if polygon.size() >= 3:
		draw_colored_polygon(polygon, _BELT_ARROW)


# 矢印の三角形を、このコンベアのマスの内側に切り取ったもの（マスの外に出る部分が無ければそのまま）。
# 辺にかかった矢印の残りは隣のコンベアが描くので、境目でつながって見え、行き止まりでははみ出さない。
static func chevron_polygon(pos: Vector2, tangent: Vector2) -> PackedVector2Array:
	var perp = tangent.rotated(PI * 0.5)
	var tip = pos + tangent * _ARROW_SIZE
	var left = pos - tangent * (_ARROW_SIZE * 0.4) + perp * (_ARROW_SIZE * 0.7)
	var right = pos - tangent * (_ARROW_SIZE * 0.4) - perp * (_ARROW_SIZE * 0.7)
	var triangle = PackedVector2Array([tip, left, right])
	var clipped = Geometry2D.intersect_polygons(triangle, _cell_polygon())
	return clipped[0] if not clipped.is_empty() else PackedVector2Array()


# このピースのマス（pointy-top の六角形）の角
static func _cell_polygon() -> PackedVector2Array:
	var size = Layout.make_default().size.x
	var corners := PackedVector2Array()
	for i in 6:
		var angle = deg_to_rad(60.0 * i - 30.0)
		corners.append(Vector2(cos(angle), sin(angle)) * size)
	return corners


# ---- アイテムアイコン --------------------------------------------------------


func update_item_icon():
	if not _mover or not _item_icon:
		return
	_update_slot_icon(_item_icon, _mover.get_held_item(), _mover.get_progress_ratio())
	if _item_icon_2:
		var held2 = _mover.get_held_item_2() if _mover.has_method("get_held_item_2") else ""
		var ratio2 = (
			_mover.get_progress_ratio_2() if _mover.has_method("get_progress_ratio_2") else 0.0
		)
		_update_slot_icon(_item_icon_2, held2, ratio2)


func _update_slot_icon(icon: Sprite2D, item_name: String, progress_ratio: float):
	if item_name == "":
		icon.visible = false
		return
	var item_def = ItemDB.get_item(item_name)
	if not item_def:
		icon.visible = false
		return
	icon.texture = item_def.icon
	icon.visible = true
	icon.position = _position_on_path(progress_ratio)


func _item_position_on_path() -> Vector2:
	return _position_on_path(_mover.get_progress_ratio())


func _position_on_path(t: float) -> Vector2:
	var path = _select_active_path()
	if path.size() < 2:
		return Vector2.ZERO
	var n = path.size() - 1
	var fi = t * n
	var i = clampi(int(fi), 0, n - 1)
	return path[i].lerp(path[i + 1], fi - i)


func _select_active_path() -> PackedVector2Array:
	if _paths.size() <= 1 or not _mover.has_method("get_target_direction"):
		return _path
	var target_dir = _mover.get_target_direction()
	for i in range(_output_directions.size()):
		if _output_directions[i] == target_dir:
			return _paths[i]
	return _path
