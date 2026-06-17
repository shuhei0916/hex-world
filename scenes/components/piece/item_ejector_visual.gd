class_name ItemEjectorVisual
extends Node2D

## 保持しているアイテムのアイコンを表示するビジュアル（balancer 等の搬出系で使用）。
## shapez の ItemEjectorSystem 相当の描画部。搬送状態は兄弟の mover
## （get_held_item を持つ BalancerLogic 等）から読む。ベルト描画やパス補間は持たない。
## アイテムが向かう出力方向は mover.get_target_direction() から読むため、
## 表示と実際の排出先が常に一致する（片側のみ接続・詰まり時も食い違わない）。

@onready var _piece: Piece = get_parent()
@onready var _mover: Node = _find_mover()
@onready var _item_icon: Sprite2D = $ItemIcon


func _ready():
	# 描画レイヤー: miner の出力アイテムと同じく基礎タイル(10)より奥(7)に置き、
	# 施設の背後から出力ポート端に覗かせる。
	_item_icon.z_index = 7
	_item_icon.z_as_relative = false


func _find_mover() -> Node:
	for sibling in get_parent().get_children():
		if sibling.has_method("get_held_item"):
			return sibling
	return null


func _process(_delta: float):
	update_item_icon()


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
	# 出力hexの中心(起点)→ポート端(終点)へ、進捗(progress)に応じてスライドさせる（shapez のスロット進行）。
	var ends = _slide_endpoints(_target_direction())
	var t = 1.0
	if _mover.has_method("get_progress_ratio"):
		t = _mover.get_progress_ratio()
	_item_icon.position = ends[0].lerp(ends[1], t)


# mover が示す排出方向(0-5)。取得できなければ主出力ポート方向にフォールバック。
func _target_direction() -> int:
	if _mover and _mover.has_method("get_target_direction"):
		var dir = _mover.get_target_direction()
		if dir >= 0:
			return dir
	# 排出先が無い場合は主出力ポートの方向を使う（飛び出し先の目安）。
	if _piece:
		var ports = _piece.get_output_ports()
		if not ports.is_empty():
			return ports[0].direction
	return -1


# 指定方向の出力ポートについて [起点=出力hex中心, 終点=ポート端] を返す。該当無しは [ZERO, ZERO]。
func _slide_endpoints(direction: int) -> Array:
	if direction < 0 or not _piece:
		return [Vector2.ZERO, Vector2.ZERO]
	var layout = Layout.make_default()
	for port in _piece.get_output_ports():
		if port.direction == direction:
			var hex_center = Layout.hex_to_pixel(layout, port.hex)
			var edge = Layout.hex_to_pixel(layout, Hex.hex_directions[direction]) * 0.5
			return [hex_center, hex_center + edge]
	return [Vector2.ZERO, Vector2.ZERO]
