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
const BELT_WIDTH = 56.0  # ベルトの見た目の幅(px)

# パス幾何 [in_edge, center, out_edge]。ベルト配置とアイテム補間の両方で参照する。
var _path: PackedVector2Array = PackedVector2Array()
var _belts: Array[Sprite2D] = []
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
	_animate_belts(delta)
	update_item_icon()


func set_input_direction(direction: int):
	_input_direction = direction
	refresh_belt()


# 入力辺→中心→出力辺の2セグメントを forward ベルトスプライトで描く。
# ヘックスの60°/120°曲がりにも、各半区間を直線ベルトで繋ぐことで対応する。
func refresh_belt():
	for belt in _belts:
		belt.queue_free()
	_belts.clear()
	_path = PackedVector2Array()
	var ports = _piece.get_output_ports()
	if ports.is_empty():
		return
	var layout = Layout.make_default()
	var output_dir = ports[0]["direction"]
	var input_dir = _input_direction if _input_direction >= 0 else (output_dir + 3) % 6
	var out_edge = Layout.hex_to_pixel(layout, Hex.hex_directions[output_dir]) * 0.5
	var in_edge = Layout.hex_to_pixel(layout, Hex.hex_directions[input_dir]) * 0.5
	_path = PackedVector2Array([in_edge, Vector2.ZERO, out_edge])
	# 入力半分(in_edge→中心)と出力半分(中心→out_edge)。矢印は搬送方向を向く。
	_belts.append(_make_belt_segment(in_edge, Vector2.ZERO))
	_belts.append(_make_belt_segment(Vector2.ZERO, out_edge))


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


func _animate_belts(delta: float):
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
