class_name ItemEjector
extends Node2D

## アイテムを保持し接続先ピースへ搬出するコンポーネント（shapez の ItemEjector 相当）。
## 出力アイテムは内部スロット(_item/_count)が直接保持する（汎用 Inventory は使わない）。
## 接続先への巡回搬出は EjectorRouter に委譲。保持アイテムの描画は ItemEjectorVisual が
## get_held_item/get_target_direction を読んで担う。

var capacity: int = 1

var _ejector := EjectorRouter.new()
var _item: String = ""
var _count: int = 0
var _is_pushing: bool = false


func _process(delta: float):
	if Engine.is_editor_hint():
		return
	tick(delta)


# 毎 tick 搬出を再試行する（接続先が後から空いた場合の滞留アイテム再送のため）。
func tick(_delta: float):
	try_push()


func set_connected_pieces(pieces: Array, directions: Array = []) -> void:
	_ejector.set_connections(pieces, directions)
	try_push()


func get_connected_pieces() -> Array:
	return _ejector.connected_pieces


func add_item(item_name: String, amount: int):
	if _item == "" or _item == item_name:
		_item = item_name
		_count += amount
		try_push()


func consume_item(item_name: String, amount: int):
	if _item == item_name:
		_count -= amount
		if _count <= 0:
			_item = ""
			_count = 0


func get_item_count(item_name: String) -> int:
	return _count if _item == item_name else 0


func get_total_item_count() -> int:
	return _count


func set_capacity(n: int):
	capacity = n


func is_full() -> bool:
	return _count >= capacity


func is_empty() -> bool:
	return _count <= 0


# 描画用: 保持アイテムと、実際に向かう出力方向(0-5, 無ければ-1)。
func get_held_item() -> String:
	return _item


func get_target_direction() -> int:
	return _ejector.target_direction(_item)


func try_push():
	if _is_pushing or _item == "" or _ejector.connected_pieces.is_empty():
		return
	_is_pushing = true
	while _item != "" and _ejector.try_eject(_item):
		consume_item(_item, 1)
	_is_pushing = false
