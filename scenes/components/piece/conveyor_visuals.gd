class_name ConveyorVisuals
extends Node2D

## コンベア/スプリッターのライン描画と保持アイテムのアイコン表示を担当する。
## 搬送状態は兄弟の mover（get_held_item を持つ ConveyorLogic / SplitterLogic）から読む。

## shapez 流のベルトアニメ: forward フレームを時刻で順送りして「流れ」を表現する。
const BELT_ANIM_COUNT = 14
const BELT_FPS = 20.0
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

# forward フレームを90°回転したテクスチャのキャッシュ。
# Line2D はテクスチャ横軸を線方向に貼るため、矢印が縦の素材を回して進行方向に合わせる。
static var _rotated_frames: Array[Texture2D] = []

@export var show_line: bool = true

# パス幾何 [in_edge, center, out_edge]。ベルト描画とアイテム補間の両方で参照する。
var _path: PackedVector2Array = PackedVector2Array()
var _belt: Line2D = null
var _input_direction: int = -1
var _elapsed: float = 0.0

@onready var _piece: Piece = get_parent()
@onready var _mover: Node = _find_mover()
@onready var _item_icon: Sprite2D = $ItemIcon


# 経過時間から表示すべきフレーム index（0..BELT_ANIM_COUNT-1）を返す。
static func frame_for_time(elapsed: float) -> int:
	return int(elapsed * BELT_FPS) % BELT_ANIM_COUNT


# Line2D 用に90°回転したフレーム配列（初回のみ生成してキャッシュ）。
static func belt_frames() -> Array[Texture2D]:
	if _rotated_frames.is_empty():
		for tex in BELT_FRAMES:
			var img := tex.get_image()
			img.rotate_90(CLOCKWISE)
			_rotated_frames.append(ImageTexture.create_from_image(img))
	return _rotated_frames


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


# 入力辺→中心→出力辺を1本の Line2D リボンで描く。
# joint_mode=ROUND で角を丸めて繋ぐので、ヘックスの60°/120°曲がりでも継ぎ目なく連続して見える。
func refresh_belt():
	if _belt:
		_belt.queue_free()
		_belt = null
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
	_belt = Line2D.new()
	# 描画レイヤー: ベルトは土台(5)とアイテム(7)の間（6）。
	_belt.z_index = 6
	_belt.z_as_relative = false
	_belt.width = BELT_WIDTH
	_belt.texture_mode = Line2D.LINE_TEXTURE_TILE
	_belt.joint_mode = Line2D.LINE_JOINT_ROUND
	_belt.round_precision = 16
	_belt.texture = belt_frames()[0]
	_belt.points = _path
	add_child(_belt)


func _animate_belt(delta: float):
	if not _belt:
		return
	_elapsed += delta
	_belt.texture = belt_frames()[frame_for_time(_elapsed)]


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
