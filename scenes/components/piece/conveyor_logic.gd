class_name ConveyorLogic
extends Node

## コンベアの搬送ロジック。アイテムを1個保持し、TRANSFER_TIME 経過後に
## EjectorRouter がラウンドロビンで選んだ接続先へ渡す（自然な分岐に対応）。
## 分岐（接続先2つ以上）では、アイテムが中心に達した時点で行き先の方向を確定し、
## 以後は出口の空き状況が変わってもその方向へ進む。
## 保持＋タイマーは TransferBuffer に、搬出先選択は EjectorRouter に委譲する。

const CENTER_TIME = TransferBuffer.TRANSFER_TIME * 0.5

var _buffer := TransferBuffer.new()
var _ejector := EjectorRouter.new()
var _locked_direction: int = -1  # 中心で確定した行き先。-1 は未確定


func set_connected_pieces(pieces: Array, directions: Array = []) -> void:
	_ejector.set_connections(pieces, directions)
	# 行き先の出口が無くなったら確定を解除する（止まり続けないように）
	if not _locked_direction in directions:
		_locked_direction = -1


func get_connected_pieces() -> Array:
	return _ejector.connected_pieces


func can_accept_item(_item_name: String) -> bool:
	# 中心で行き先待ちのアイテムがあるときに受け入れると、2個目も中心まで進んで重なる
	if _is_waiting_at_center():
		return false
	return _buffer.can_accept()


func add_item(item_name: String, _amount: int):
	_buffer.receive(item_name)


func get_item_count(item_name: String) -> int:
	return _buffer.get_count(item_name)


func get_held_item() -> String:
	return _buffer.held_item


func get_held_item_2() -> String:
	return _buffer.held_item_2


func get_progress_ratio() -> float:
	return _buffer.get_progress_ratio()


func get_progress_ratio_2() -> float:
	return _buffer.get_progress_ratio_2()


func get_target_direction() -> int:
	if _locked_direction >= 0:
		return _locked_direction
	return _ejector.target_direction(_buffer.held_item)


func tick(delta: float):
	var limit = TransferBuffer.TRANSFER_TIME
	if _is_branching() and _locked_direction < 0:
		# 中心に達するタイミングで行き先を確定する。確定できなければ中心で待つ
		if _buffer.held_item != "" and _buffer.progress + delta >= CENTER_TIME:
			_locked_direction = _ejector.target_direction(_buffer.held_item)
		if _locked_direction < 0:
			limit = CENTER_TIME
	if _buffer.advance(delta, limit) and _try_eject():
		_buffer.clear()
		_locked_direction = -1


func _try_eject() -> bool:
	if _locked_direction >= 0:
		return _ejector.try_eject_to(_buffer.held_item, _locked_direction)
	return _ejector.try_eject(_buffer.held_item)


func _is_waiting_at_center() -> bool:
	return _is_branching() and _locked_direction < 0 and _buffer.held_item != ""


func _is_branching() -> bool:
	return _ejector.connected_pieces.size() >= 2
