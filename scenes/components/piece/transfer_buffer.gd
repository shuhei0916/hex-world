class_name TransferBuffer
extends RefCounted

## アイテムを1個だけ保持し、TRANSFER_TIME 経過で搬出可能になるバッファ。
## ConveyorLogic / BalancerLogic が合成で持つ（保持＋タイマーの共通部）。

const TRANSFER_TIME = 0.5

var held_item: String = ""
var progress: float = 0.0


func can_accept() -> bool:
	return held_item == ""


func receive(item_name: String) -> void:
	if held_item != "":
		return
	held_item = item_name
	progress = 0.0


func get_count(item_name: String) -> int:
	return 1 if held_item == item_name else 0


func clear() -> void:
	held_item = ""
	progress = 0.0


func get_progress_ratio() -> float:
	return progress / TRANSFER_TIME


# 時間を進め、搬出可能になったら true を返す。
func advance(delta: float) -> bool:
	if held_item == "":
		progress = 0.0
		return false
	progress = minf(progress + delta, TRANSFER_TIME)
	return progress >= TRANSFER_TIME
