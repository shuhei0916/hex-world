class_name TransferBuffer
extends RefCounted

## アイテムを最大2個保持し、TRANSFER_TIME 経過で搬出可能になるバッファ。
## slot1（先行）が後半（progress >= TRANSFER_TIME/2）に達したらslot2（後続）を受け入れ可能。
## slot1搬出後はslot2がslot1に昇格する。

const TRANSFER_TIME = 0.5

var held_item: String = ""
var progress: float = 0.0

var held_item_2: String = ""
var progress_2: float = 0.0


func can_accept() -> bool:
	if held_item == "":
		return true
	if held_item_2 == "" and progress >= TRANSFER_TIME * 0.5:
		return true
	return false


func receive(item_name: String) -> void:
	if held_item == "":
		held_item = item_name
		progress = 0.0
	elif held_item_2 == "" and progress >= TRANSFER_TIME * 0.5:
		held_item_2 = item_name
		progress_2 = 0.0


func get_count(item_name: String) -> int:
	var count = 0
	if held_item == item_name:
		count += 1
	if held_item_2 == item_name:
		count += 1
	return count


func clear() -> void:
	held_item = held_item_2
	progress = progress_2
	held_item_2 = ""
	progress_2 = 0.0


func get_progress_ratio() -> float:
	return progress / TRANSFER_TIME


func get_progress_ratio_2() -> float:
	return progress_2 / TRANSFER_TIME


# 時間を進め、搬出可能になったら true を返す。
func advance(delta: float) -> bool:
	if held_item_2 != "":
		progress_2 = minf(progress_2 + delta, TRANSFER_TIME * 0.5)
	if held_item == "":
		progress = 0.0
		return false
	progress = minf(progress + delta, TRANSFER_TIME)
	return progress >= TRANSFER_TIME
