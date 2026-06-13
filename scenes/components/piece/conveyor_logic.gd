class_name ConveyorLogic
extends Node

## コンベアの搬送ロジック。アイテムを1個だけ保持し、
## TRANSFER_TIME経過後に接続先ピースへラウンドロビンで受け渡す。

const TRANSFER_TIME = 0.5

var held_item: String = ""
var progress: float = 0.0

var _ejector := ItemEjector.new()


func _process(delta: float):
	if Engine.is_editor_hint():
		return
	tick(delta)


func set_connected_pieces(pieces: Array) -> void:
	_ejector.connected_pieces = pieces


func get_connected_pieces() -> Array:
	return _ejector.connected_pieces


func can_accept_item(_item_name: String) -> bool:
	return held_item == ""


func add_item(item_name: String, _amount: int):
	receive_item(item_name)


func get_item_count(item_name: String) -> int:
	return 1 if held_item == item_name else 0


func receive_item(item_name: String):
	if held_item != "":
		return
	held_item = item_name
	progress = 0.0


func tick(delta: float):
	if held_item == "":
		progress = 0.0
		return
	progress = minf(progress + delta, TRANSFER_TIME)
	if progress >= TRANSFER_TIME:
		_try_deliver()


func _try_deliver():
	if _ejector.try_eject(held_item):
		held_item = ""
		progress = 0.0
