class_name ConveyorVisuals
extends Node2D

## コンベア/スプリッターのライン描画と保持アイテムのアイコン表示を担当する。
## 搬送状態は兄弟の mover（get_held_item を持つ ConveyorLogic / SplitterLogic）から読む。

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

const BELT_WIDTH = 56.0  # ベルトの見た目の幅(px)
const BELT_TEXTURE_SIZE = 192.0  # forward フレームの一辺(px)

@export var show_line: bool = true

# パス幾何 [in_edge, center, out_edge]。ベルト描画とアイテム補間の両方で参照する。
var _path: PackedVector2Array = PackedVector2Array()
var _belts: Array[Polygon2D] = []
var _corner_fills: Array[Polygon2D] = []
var _input_direction: int = -1
var _elapsed: float = 0.0

@onready var _piece: Piece = get_parent()
@onready var _mover: Node = _find_mover()
@onready var _item_icon: Sprite2D = $ItemIcon


# 経過時間から表示すべきフレーム index（0..BELT_ANIM_COUNT-1）を返す。
static func frame_for_time(elapsed: float) -> int:
	return int(elapsed * BELT_FPS) % BELT_ANIM_COUNT


func _ready():
	# 描画レイヤー: コンベア上のアイテムは土台(5)・ベルト(6)より手前（7）。
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
	_animate_belt(delta)
	update_item_icon()


func set_input_direction(direction: int):
	_input_direction = direction
	refresh_belt()


# 入力辺→中心→出力辺を、中心で垂直カットした2枚のテクスチャ付き四角形(Polygon2D)で描く。
# 曲がり時は中心に生じる隙間/重なりをコーナー三角形で埋めて連続させる（ベベル接合）。
# 鋭角でも破綻しないよう、スパイクするマイターは使わない。
func refresh_belt():
	for belt in _belts:
		belt.queue_free()
	_belts.clear()
	for fill in _corner_fills:
		fill.queue_free()
	_corner_fills.clear()
	_path = PackedVector2Array()
	if not show_line:
		return
	var ports = _piece.get_output_ports()
	if ports.is_empty():
		return
	var layout = Layout.make_default()
	var output_dir = ports[0]["direction"]
	var input_dir = _input_direction if _input_direction >= 0 else (output_dir + 3) % 6
	var out_edge = Layout.hex_to_pixel(layout, Hex.hex_directions[output_dir]) * 0.5
	var in_edge = Layout.hex_to_pixel(layout, Hex.hex_directions[input_dir]) * 0.5
	_path = PackedVector2Array([in_edge, Vector2.ZERO, out_edge])

	var d_in = (Vector2.ZERO - in_edge).normalized()  # 入力半分の搬送方向
	var d_out = (out_edge - Vector2.ZERO).normalized()  # 出力半分の搬送方向
	var half = BELT_WIDTH / 2.0
	var n_in = Vector2(-d_in.y, d_in.x) * half
	var n_out = Vector2(-d_out.y, d_out.x) * half

	# 入力半分: in_edge(根本) → 中心(先端、垂直カット)。矢印は搬送方向(先端=テクスチャ上端Y=0)。
	_belts.append(_make_belt_quad([in_edge + n_in, n_in, -n_in, in_edge - n_in]))
	# 出力半分: 中心(根本) → out_edge(先端)。
	_belts.append(_make_belt_quad([n_out, out_edge + n_out, out_edge - n_out, -n_out]))

	# 曲がりなら中心の左右ウェッジを三角形で埋める（片側は隙間埋め、片側は重なりで無害）。
	if not d_in.is_equal_approx(d_out):
		_corner_fills.append(_make_corner_fill(n_in, n_out))
		_corner_fills.append(_make_corner_fill(-n_in, -n_out))


# 4頂点 [根本左, 先端左, 先端右, 根本右] の順で、テクスチャを長手方向に貼った四角形を作る。
func _make_belt_quad(verts: Array) -> Polygon2D:
	var s = BELT_TEXTURE_SIZE
	var poly = Polygon2D.new()
	poly.polygon = PackedVector2Array(verts)
	# UV: 左辺X=0 / 右辺X=s、先端(搬送方向)Y=0 / 根本Y=s（矢印が先端を向く）
	poly.uv = PackedVector2Array([Vector2(0, s), Vector2(0, 0), Vector2(s, 0), Vector2(s, s)])
	poly.texture = BELT_FRAMES[0]
	# 描画レイヤー: ベルトは土台(5)とアイテム(7)の間（6）。
	poly.z_index = 6
	poly.z_as_relative = false
	add_child(poly)
	return poly


# 中心の角を埋める三角形 [a, 中心, b]。ベルトの無地部分(端の灰色)をUVで拾って色を合わせる。
func _make_corner_fill(a: Vector2, b: Vector2) -> Polygon2D:
	var g = BELT_TEXTURE_SIZE * 0.06  # テクスチャ端＝チェブロンの無い灰色帯
	var poly = Polygon2D.new()
	poly.polygon = PackedVector2Array([a, Vector2.ZERO, b])
	poly.uv = PackedVector2Array([Vector2(g, g), Vector2(g, g), Vector2(g, g)])
	poly.texture = BELT_FRAMES[0]
	poly.z_index = 6
	poly.z_as_relative = false
	add_child(poly)
	return poly


func _animate_belt(delta: float):
	if _belts.is_empty():
		return
	_elapsed += delta
	var frame = frame_for_time(_elapsed)
	for belt in _belts:
		belt.texture = BELT_FRAMES[frame]


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
	if _path.size() < 3:
		return Vector2.ZERO
	var t = _mover.get_progress_ratio()
	if t < 0.5:
		return _path[0].lerp(_path[1], t * 2.0)
	return _path[1].lerp(_path[2], (t - 0.5) * 2.0)
