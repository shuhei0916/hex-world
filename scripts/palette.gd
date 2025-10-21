class_name Palette
extends Node

const DEFAULT_SLOT_COUNT := 9

var slots: Array = []
var active_index: int = 0

func _init():
	_initialize_slots()
	active_index = 0

func _initialize_slots():
	slots.clear()
	for index in range(DEFAULT_SLOT_COUNT):
		slots.append(_create_slot(index))

func _create_slot(index: int) -> Dictionary:
	return {
		"index": index,
		"piece_id": null,
		"is_highlighted": index == active_index
	}

func get_slot_count() -> int:
	return slots.size()

func get_active_index() -> int:
	return active_index

func handle_number_key_input(keycode: int):
	var target_index = _keycode_to_slot_index(keycode)
	if target_index == -1:
		return
	_set_active_index(target_index)

func _keycode_to_slot_index(keycode: int) -> int:
	var numeric_value = keycode - KEY_0
	if numeric_value <= 0 or numeric_value > DEFAULT_SLOT_COUNT:
		return -1
	return numeric_value - 1

func _set_active_index(index: int):
	if index == active_index:
		return
	if index < 0 or index >= slots.size():
		return
	_update_highlight(active_index, false)
	active_index = index
	_update_highlight(active_index, true)

func _update_highlight(index: int, state: bool):
	if index < 0 or index >= slots.size():
		return
	slots[index]["is_highlighted"] = state
