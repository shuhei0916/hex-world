class_name ConveyorLogic
extends Node

## コンベアの搬送ロジック。アイテムを1個保持し、TRANSFER_TIME 経過後に
## 唯一の接続先へ渡す（単一出力。分岐は SplitterLogic が担う）。
## 保持＋タイマーは TransferBuffer に委譲する。

var connected_pieces: Array = []

var _buffer := TransferBuffer.new()


func _process(delta: float):
	if Engine.is_editor_hint():
		return
	tick(delta)


func set_connected_pieces(pieces: Array, _directions: Array = []) -> void:
	# コンベアは単一出力なので方向情報は使わない（ベルト描画は set_input_direction が担当）。
	connected_pieces = pieces


func get_connected_pieces() -> Array:
	return connected_pieces


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
		_try_deliver()


func _try_deliver():
	for target in connected_pieces:
		if target.has_method("can_accept_item") and target.has_method("add_item"):
			if target.can_accept_item(_buffer.held_item):
				target.add_item(_buffer.held_item, 1)
				_buffer.clear()
				return
