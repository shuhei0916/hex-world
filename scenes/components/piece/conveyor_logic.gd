class_name ConveyorLogic
extends Node

## コンベアの搬送ロジック。アイテムを1個保持し、TRANSFER_TIME 経過後に
## 唯一の接続先へ渡す（単一出力。分岐は BalancerLogic が担う）。
## 保持＋タイマーは TransferBuffer に、搬出は EjectorRouter に委譲する。

var _buffer := TransferBuffer.new()
var _ejector := EjectorRouter.new()


func set_connected_pieces(pieces: Array, directions: Array = []) -> void:
	_ejector.set_connections(pieces, directions)


func get_connected_pieces() -> Array:
	return _ejector.connected_pieces


func can_accept_item(_item_name: String) -> bool:
	return _buffer.can_accept()


func add_item(item_name: String, _amount: int):
	_buffer.receive(item_name)


func get_item_count(item_name: String) -> int:
	return _buffer.get_count(item_name)


func get_held_item() -> String:
	return _buffer.held_item


func get_progress_ratio() -> float:
	return _buffer.get_progress_ratio()


func tick(delta: float):
	if _buffer.advance(delta):
		if _ejector.try_eject(_buffer.held_item):
			_buffer.clear()
