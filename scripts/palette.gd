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
