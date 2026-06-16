class_name ItemEjector
extends Node2D

## アイテムをスタックし、接続先ピースへ搬出するコンポーネント（shapez の ItemEjector 相当）。
## ストレージは $Inventory に、接続先への巡回搬出は EjectorRouter に委譲する。

var _ejector := EjectorRouter.new()
var _is_pushing: bool = false

@onready var inventory: Node2D = $Inventory


func _ready():
	# 描画レイヤー: 機械の出力はみ出しアイテムは施設タイル(10)より奥（7）。
	z_index = 7
	z_as_relative = false
	inventory.inventory_changed.connect(_push_items)


func _process(delta: float):
	if Engine.is_editor_hint():
		return
	tick(delta)


# 毎 tick 搬出を再試行する。接続先が後から空いた場合に滞留アイテムを再送するため
# （inventory_changed は自分の在庫変化時しか発火しないので、これが無いと詰まる）。
func tick(_delta: float):
	try_push()


func set_connected_pieces(pieces: Array, directions: Array = []) -> void:
	_ejector.set_connections(pieces, directions)
	try_push()


func get_connected_pieces() -> Array:
	return _ejector.connected_pieces


func add_item(item_name: String, amount: int):
	inventory.add_item(item_name, amount)


func consume_item(item_name: String, amount: int):
	inventory.consume_item(item_name, amount)


func get_item_count(item_name: String) -> int:
	return inventory.get_item_count(item_name)


func get_total_item_count() -> int:
	return inventory.get_total_item_count()


func set_capacity(n: int):
	inventory.set_capacity(n)


func is_full() -> bool:
	return inventory.is_full()


func is_empty() -> bool:
	return inventory.is_empty()


func try_push():
	_push_items()


func _push_items():
	if _is_pushing:
		return
	if inventory.is_empty() or _ejector.connected_pieces.is_empty():
		return

	_is_pushing = true
	var still_pushing = true
	while still_pushing and not inventory.is_empty():
		still_pushing = false
		for item_name in inventory.get_item_names().duplicate():
			if _ejector.try_eject(item_name):
				consume_item(item_name, 1)
				still_pushing = true
				break

	_is_pushing = false
