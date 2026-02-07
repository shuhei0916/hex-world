class_name PaletteUI
extends Control

const HexTileScene = preload("res://scenes/components/hex_tile/hex_tile.tscn")

@export var slot_size: Vector2 = Vector2(48, 48)
@export var slot_margin: float = 8.0
@export var inactive_color: Color = Color(0.2, 0.2, 0.2, 0.85)
@export var active_color: Color = Color(0.9, 0.9, 0.3, 1.0)

var palette: Palette:
	set = set_palette
var slot_rects: Array[ColorRect] = []
var highlighted_index: int = 0
var _is_initialized: bool = false


func _ready():
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var viewport = get_viewport()
	if viewport:
		viewport.size_changed.connect(_on_viewport_resized)

	# すでにパレットがセットされている場合は初期化
	if palette:
		_initialize_ui()


func set_palette(new_palette: Palette):
	if palette == new_palette:
		return

	if palette:
		if palette.active_slot_changed.is_connected(_on_active_slot_changed):
			palette.active_slot_changed.disconnect(_on_active_slot_changed)

	palette = new_palette

	if palette:
		palette.active_slot_changed.connect(_on_active_slot_changed)
		if is_node_ready():
			_initialize_ui()


func _initialize_ui():
	if not palette:
		return

	_create_slots()
	_refresh_slots()
	_update_slot_positions()
	_is_initialized = true


func _create_slots():
	for rect in slot_rects:
		if rect:
			rect.queue_free()
	slot_rects.clear()

	if not palette:
		return

	var slot_count = palette.get_slot_count()
	for i in range(slot_count):
		var rect := ColorRect.new()
		rect.name = "Slot%d" % i
		rect.color = inactive_color
		rect.mouse_filter = Control.MOUSE_FILTER_STOP
		rect.custom_minimum_size = slot_size
		rect.set_size(slot_size)

		# 入力イベントを接続
		rect.gui_input.connect(_on_slot_gui_input.bind(i))

		# ピースのプレビューを追加
		var piece_data = palette.get_piece_data_for_slot(i)
		if not piece_data.is_empty():
			_create_piece_icon(rect, piece_data)

		add_child(rect)
		slot_rects.append(rect)


func _on_slot_gui_input(event: InputEvent, index: int):
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if palette:
				palette.select_slot(index)


func _create_piece_icon(parent: Control, piece_data: Dictionary):
	var icon_root = Node2D.new()
	icon_root.name = "IconRoot"
	icon_root.position = slot_size / 2.0
	icon_root.scale = Vector2(0.15, 0.15)
	parent.add_child(icon_root)

	var shape = piece_data["shape"]
	var color = piece_data["color"]

	# UI表示用のレイアウト（サイズはGridManagerと合わせるか適当に）
	var layout = Layout.new(Layout.layout_pointy, Vector2(42, 42), Vector2(0, 0))

	for hex in shape:
		var tile = HexTileScene.instantiate()
		icon_root.add_child(tile)
		tile.position = Layout.hex_to_pixel(layout, hex)
		tile.setup_hex(hex)
		tile.set_color(color)


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
	if not palette:
		return

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


func get_active_piece_data() -> Dictionary:
	if not palette:
		return {}
	return palette.get_piece_data_for_slot(palette.get_active_index())
