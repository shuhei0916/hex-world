class_name Palette
extends Node

signal active_slot_changed(new_index: int, old_index: int)

const DEFAULT_SLOT_COUNT := 9

var slots: Array = []
var active_index: int = -1  # 初期状態は非選択


func _init():
	active_index = -1
	_initialize_slots()


func _initialize_slots():
	slots.clear()
	var assigned_types = _get_default_piece_assignments()
	for index in range(DEFAULT_SLOT_COUNT):
		var slot_data = _create_slot(index)
		slot_data["piece_type"] = assigned_types[index] if index < assigned_types.size() else null
		slots.append(slot_data)


func _create_slot(index: int) -> Dictionary:
	return {"index": index, "piece_id": null, "is_highlighted": index == active_index}


func get_slot_count() -> int:
	return slots.size()


func get_active_index() -> int:
	return active_index


func get_highlighted_index() -> int:
	for i in range(slots.size()):
		if slots[i].get("is_highlighted", false):
			return i
	return -1


func get_piece_type_for_slot(slot_index: int):
	if slot_index < 0 or slot_index >= slots.size():
		return null
	return slots[slot_index].get("piece_type", null)


func get_piece_data_for_slot(slot_index: int) -> Dictionary:
	var piece_type = get_piece_type_for_slot(slot_index)
	if piece_type == null:
		return {}
	var data = PieceDB.get_data(piece_type)
	if data == null:
		return {}
	return {"type": piece_type, "shape": data.shape, "color": data.color}


func select_slot(index: int):
	if index < 0 or index >= slots.size():
		return

	var previous_index = active_index

	if index == active_index:
		# 同じスロットを選択した場合は非選択にする（トグル）
		deselect()
	else:
		# 新しいスロットを選択
		if previous_index != -1:
			_update_highlight(previous_index, false)
		active_index = index
		_update_highlight(active_index, true)
		emit_signal("active_slot_changed", active_index, previous_index)


func deselect():
	var previous_index = active_index
	if previous_index == -1:
		return

	active_index = -1
	_update_highlight(previous_index, false)
	emit_signal("active_slot_changed", active_index, previous_index)


func _update_highlight(index: int, state: bool):
	if index < 0 or index >= slots.size():
		return
	slots[index]["is_highlighted"] = state


func is_slot_highlighted(index: int) -> bool:
	if index < 0 or index >= slots.size():
		return false
	return slots[index].get("is_highlighted", false)


func _get_default_piece_assignments() -> Array:
	return [
		PieceDB.PieceType.BEE,
		PieceDB.PieceType.WORM,
		PieceDB.PieceType.WAVE,
		PieceDB.PieceType.PISTOL,
		PieceDB.PieceType.BAR,
		PieceDB.PieceType.PROPELLER,
		PieceDB.PieceType.ARCH,
		PieceDB.PieceType.CHEST
	]
