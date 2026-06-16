class_name ItemEjectorVisual
extends Node2D

## 保持しているアイテムのアイコンを表示するビジュアル（splitter 等の搬出系で使用）。
## shapez の ItemEjectorSystem 相当の描画部。搬送状態は兄弟の mover
## （get_held_item を持つ SplitterLogic 等）から読む。ベルト描画やパス補間は持たない。

@onready var _mover: Node = _find_mover()
@onready var _item_icon: Sprite2D = $ItemIcon


func _ready():
	# 描画レイヤー: 基礎タイル(10)より手前に保持アイテムを出す。
	_item_icon.z_index = 11
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
	# 保持アイテムはピース中心に表示する。
	_item_icon.position = Vector2.ZERO
