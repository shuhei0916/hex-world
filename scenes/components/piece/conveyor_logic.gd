class_name ConveyorLogic
extends Node

## コンベアの搬送ロジック。アイテムを1個だけ保持し、
## TRANSFER_TIME経過後に接続先ピースへラウンドロビンで受け渡す。

const TRANSFER_TIME = 0.5

var held_item: String = ""
var progress: float = 0.0
var connected_pieces: Array = []
var _rr_index: int = 0


func _process(delta: float):
	if Engine.is_editor_hint():
		return
	tick(delta)


func can_accept() -> bool:
	return held_item == ""


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
	var n = connected_pieces.size()
	if n == 0:
		return
	for i in range(n):
		var target = connected_pieces[(_rr_index + i) % n]
		if target.has_method("can_accept_item") and target.has_method("add_item"):
			if target.can_accept_item(held_item):
				target.add_item(held_item, 1)
				_rr_index = (_rr_index + 1) % n
				held_item = ""
				progress = 0.0
				return
