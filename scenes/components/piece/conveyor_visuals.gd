class_name ConveyorVisuals
extends Node2D

## コンベア/スプリッターのライン描画と保持アイテムのアイコン表示を担当する。
## 搬送状態は兄弟の mover（get_held_item を持つ ConveyorLogic / BalancerLogic）から読む。

## shapez 流のベルトアニメ: forward フレームを時刻で順送りして「流れ」を表現する。
const BELT_ANIM_COUNT = 14
# アイテムの搬送速度と同期させる: 1ヘックス渡る間(TRANSFER_TIME)にベルト柄が1周する。
const BELT_FPS = BELT_ANIM_COUNT / TransferBuffer.TRANSFER_TIME
const BELT_FRAMES: Array[Texture2D] = [
	preload("res://scenes/components/piece/belt/forward_0.png"),
	preload("res://scenes/components/piece/belt/forward_1.png"),
	preload("res://scenes/components/piece/belt/forward_2.png"),
	preload("res://scenes/components/piece/belt/forward_3.png"),
	preload("res://scenes/components/piece/belt/forward_4.png"),
	preload("res://scenes/components/piece/belt/forward_5.png"),
	preload("res://scenes/components/piece/belt/forward_6.png"),
	preload("res://scenes/components/piece/belt/forward_7.png"),
	preload("res://scenes/components/piece/belt/forward_8.png"),
	preload("res://scenes/components/piece/belt/forward_9.png"),
	preload("res://scenes/components/piece/belt/forward_10.png"),
	preload("res://scenes/components/piece/belt/forward_11.png"),
	preload("res://scenes/components/piece/belt/forward_12.png"),
	preload("res://scenes/components/piece/belt/forward_13.png"),
]

const BELT_TEXTURE_SIZE = 192.0
const BELT_WIDTH = 56.0
const CURVE_SEGMENTS = 12

# 曲線ベルトのプロシージャル描画色（forward テクスチャのトーンに合わせる）
const _BELT_FILL := Color(0.77, 0.77, 0.77, 1.0)
const _BELT_EDGE := Color(0.54, 0.54, 0.57, 1.0)
const _BELT_ARROW := Color(0.62, 0.62, 0.62, 1.0)
const _ARROW_SPACING := 18.0
const _ARROW_SIZE := 8.0

# パス幾何。直線は3点、曲線は CURVE_SEGMENTS+1 点。ベルト配置とアイテム補間の両方で参照する。
var _path: PackedVector2Array = PackedVector2Array()
var _belts: Array[Sprite2D] = []
var _input_direction: int = -1
var _elapsed: float = 0.0
var _is_curved: bool = false

@onready var _piece: Piece = get_parent()
@onready var _mover: Node = _find_mover()
@onready var _item_icon: Sprite2D = $ItemIcon


# 経過時間から表示すべきフレーム index（0..BELT_ANIM_COUNT-1）を返す。
static func frame_for_time(elapsed: float) -> int:
	return int(elapsed * BELT_FPS) % BELT_ANIM_COUNT


static func sample_bezier(
	p0: Vector2, ctrl: Vector2, p2: Vector2, segments: int
) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in range(segments + 1):
		var t = float(i) / segments
		var mt = 1.0 - t
		pts.append(mt * mt * p0 + 2.0 * mt * t * ctrl + t * t * p2)
	return pts


func _ready():
	z_index = 6
	z_as_relative = false
	_item_icon.z_index = 7
	_item_icon.z_as_relative = false
	_piece.shape_changed.connect(refresh_belt)
	refresh_belt()


func _find_mover() -> Node:
	for sibling in get_parent().get_children():
		if sibling.has_method("get_held_item"):
			return sibling
	return null


func _process(delta: float):
	_elapsed += delta
	if _is_curved:
		queue_redraw()
	else:
		_animate_belts()
	update_item_icon()


func set_input_direction(direction: int):
	_input_direction = direction
	refresh_belt()


# 直線: forward スプライト2本。曲線: 二次ベジェを CURVE_SEGMENTS 分割してプロシージャル描画。
func refresh_belt():
	for belt in _belts:
		belt.queue_free()
	_belts.clear()
	_path = PackedVector2Array()
	_is_curved = false
	var ports = _piece.get_output_ports()
	if ports.is_empty():
		return
	var layout = Layout.make_default()
	var output_dir = ports[0]["direction"]
	var input_dir = _input_direction if _input_direction >= 0 else (output_dir + 3) % 6
	var out_edge = Layout.hex_to_pixel(layout, Hex.hex_directions[output_dir]) * 0.5
	var in_edge = Layout.hex_to_pixel(layout, Hex.hex_directions[input_dir]) * 0.5
	var is_straight = (input_dir + 3) % 6 == output_dir
	if is_straight:
		_path = sample_bezier(in_edge, Vector2.ZERO, out_edge, 2)
		_belts.append(_make_belt_segment(_path[0], _path[1]))
		_belts.append(_make_belt_segment(_path[1], _path[2]))
	else:
		_is_curved = true
		_path = sample_bezier(in_edge, Vector2.ZERO, out_edge, CURVE_SEGMENTS)
		queue_redraw()


func _make_belt_segment(from: Vector2, to: Vector2) -> Sprite2D:
	var vec = to - from
	var sprite = Sprite2D.new()
	sprite.texture = BELT_FRAMES[0]
	# 描画レイヤー: ベルトは土台(5)とアイテム(7)の間（6）。
	sprite.z_index = 6
	sprite.z_as_relative = false
	sprite.position = (from + to) * 0.5
	# テクスチャの矢印は上(-Y)向き。-Y を vec 方向へ向ける。
	sprite.rotation = vec.angle() + PI / 2.0
	sprite.scale = Vector2(BELT_WIDTH / BELT_TEXTURE_SIZE, vec.length() / BELT_TEXTURE_SIZE)
	add_child(sprite)
	return sprite


func _animate_belts():
	if _belts.is_empty():
		return
	var frame = frame_for_time(_elapsed)
	for belt in _belts:
		belt.texture = BELT_FRAMES[frame]


# ---- 曲線ベルトのプロシージャル描画 ----------------------------------------


func _draw():
	if not _is_curved or _path.size() < 2:
		return
	_draw_belt_ribbon()
	_draw_belt_arrows()


func _draw_belt_ribbon():
	var n = _path.size()
	var left_pts := PackedVector2Array()
	var right_pts := PackedVector2Array()
	for i in range(n):
		var tangent := _path_tangent_at(i)
		var half_w := tangent.rotated(PI * 0.5) * (BELT_WIDTH * 0.5)
		left_pts.append(_path[i] + half_w)
		right_pts.append(_path[i] - half_w)
	var poly := PackedVector2Array(left_pts)
	for i in range(right_pts.size() - 1, -1, -1):
		poly.append(right_pts[i])
	draw_colored_polygon(poly, _BELT_FILL)
	draw_polyline(left_pts, _BELT_EDGE, 3.0)
	draw_polyline(right_pts, _BELT_EDGE, 3.0)


func _draw_belt_arrows():
	var total_len := _path_arc_length()
	if total_len < 1.0:
		return
	var anim_offset: float = fmod(
		_elapsed * total_len / TransferBuffer.TRANSFER_TIME, _ARROW_SPACING
	)
	var dist: float = 0.0
	var next_arrow: float = anim_offset
	for i in range(_path.size() - 1):
		var seg_len = (_path[i + 1] - _path[i]).length()
		while next_arrow <= dist + seg_len:
			var local_t = (next_arrow - dist) / seg_len
			var pos = _path[i].lerp(_path[i + 1], local_t)
			var tangent = (_path[i + 1] - _path[i]).normalized()
			_draw_chevron(pos, tangent)
			next_arrow += _ARROW_SPACING
		dist += seg_len


func _draw_chevron(pos: Vector2, tangent: Vector2):
	var perp = tangent.rotated(PI * 0.5)
	var tip = pos + tangent * _ARROW_SIZE
	var left = pos - tangent * (_ARROW_SIZE * 0.4) + perp * (_ARROW_SIZE * 0.7)
	var right = pos - tangent * (_ARROW_SIZE * 0.4) - perp * (_ARROW_SIZE * 0.7)
	draw_colored_polygon(PackedVector2Array([tip, left, right]), _BELT_ARROW)


func _path_tangent_at(i: int) -> Vector2:
	var n = _path.size()
	if n < 2:
		return Vector2.UP
	if i == 0:
		return (_path[1] - _path[0]).normalized()
	if i == n - 1:
		return (_path[n - 1] - _path[n - 2]).normalized()
	return (_path[i + 1] - _path[i - 1]).normalized()


func _path_arc_length() -> float:
	var total := 0.0
	for i in range(_path.size() - 1):
		total += (_path[i + 1] - _path[i]).length()
	return total


# ---- アイテムアイコン --------------------------------------------------------


func update_item_icon():
	if not _mover or not _item_icon:
		return
	var held_item = _mover.get_held_item()
	if held_item == "":
		_item_icon.visible = false
		return
	var item_def = ItemDB.get_item(held_item)
	if not item_def:
		_item_icon.visible = false
		return
	_item_icon.texture = item_def.icon
	_item_icon.visible = true
	_item_icon.position = _item_position_on_path()


func _item_position_on_path() -> Vector2:
	if _path.size() < 2:
		return Vector2.ZERO
	var t = _mover.get_progress_ratio()
	var n = _path.size() - 1
	var fi = t * n
	var i = clampi(int(fi), 0, n - 1)
	return _path[i].lerp(_path[i + 1], fi - i)
