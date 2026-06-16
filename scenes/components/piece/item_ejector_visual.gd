class_name ItemEjectorVisual
extends Node2D

## 保持しているアイテムのアイコンを表示するビジュアル（splitter 等の搬出系で使用）。
## shapez の ItemEjectorSystem 相当の描画部。搬送状態は兄弟の mover
## （get_held_item を持つ SplitterLogic 等）から読む。ベルト描画やパス補間は持たない。

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
	# miner/balancer 同様、出力ポート端へ飛び出して表示する。
	_item_icon.position = _output_edge_position()


# 主出力ポートのエッジ位置（ピース原点基準）。出力が無ければ中心。
func _output_edge_position() -> Vector2:
	if not _piece:
		return Vector2.ZERO
	var ports = _piece.get_output_ports()
	if ports.is_empty():
		return Vector2.ZERO
	var layout = Layout.make_default()
	var port = ports[0]
	var hex_pos = Layout.hex_to_pixel(layout, port.hex)
	var edge = Layout.hex_to_pixel(layout, Hex.hex_directions[port.direction]) * 0.5
	return hex_pos + edge
