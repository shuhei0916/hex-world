class_name PaletteUI
extends Control

@export var slot_size: Vector2 = Vector2(48, 48)
@export var slot_margin: float = 8.0
@export var inactive_color: Color = Color(0.2, 0.2, 0.2, 0.85)
@export var active_color: Color = Color(0.9, 0.9, 0.3, 1.0)

var palette: Palette
var slot_rects: Array[ColorRect] = []
var highlighted_index: int = 0
var _is_initialized: bool = false

func _ready():
	if _is_initialized:
		return
	_is_initialized = true
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	palette = Palette.new()
	palette.connect("active_slot_changed", Callable(self, "_on_active_slot_changed"))
	_create_slots()
	_refresh_slots()
	_update_slot_positions()
	get_viewport().connect("size_changed", Callable(self, "_on_viewport_resized"))

func _create_slots():
	for rect in slot_rects:
		if rect:
			rect.queue_free()
	slot_rects.clear()
	var slot_count = palette.get_slot_count()
	for i in range(slot_count):
		var rect := ColorRect.new()
		rect.name = "Slot%d" % i
		rect.color = inactive_color
		rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		rect.custom_minimum_size = slot_size
		rect.set_size(slot_size)
		add_child(rect)
		slot_rects.append(rect)

func _update_slot_positions():
	var viewport_size = get_viewport_rect().size
	var slot_count = slot_rects.size()
	if slot_count == 0:
		return
	var total_width = slot_size.x * slot_count + slot_margin * float(slot_count - 1)
	var start_x = (viewport_size.x - total_width) * 0.5
	var y_pos = viewport_size.y - slot_size.y - slot_margin
	for i in range(slot_count):
		var rect := slot_rects[i]
		if rect:
			var x = start_x + i * (slot_size.x + slot_margin)
			rect.position = Vector2(x, y_pos)
			rect.set_size(slot_size)

func _refresh_slots():
	highlighted_index = palette.get_highlighted_index()
	for i in range(slot_rects.size()):
		var rect := slot_rects[i]
		if rect:
			rect.color = active_color if i == highlighted_index else inactive_color

func _on_active_slot_changed(new_index: int, _old_index: int):
	highlighted_index = new_index
	_refresh_slots()

func _on_viewport_resized():
	_update_slot_positions()

func get_slot_count() -> int:
	return slot_rects.size()

func get_highlighted_index() -> int:
	return highlighted_index

func process_input_event(event: InputEvent):
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode >= KEY_1 and event.keycode <= KEY_9:
			palette.handle_number_key_input(event.keycode)

func get_palette() -> Palette:
	return palette

func get_active_piece_data() -> Dictionary:
	return palette.get_piece_data_for_slot(palette.get_active_index())
