class_name HUD
extends CanvasLayer

const HexTileScene = preload("res://scenes/components/hex_tile/hex_tile.tscn")

@export var inactive_color: Color = Color(0.2, 0.2, 0.2, 0.85)
@export var active_color: Color = Color(0.9, 0.9, 0.3, 1.0)

var piece_placer: PiecePlacer

var slot_rects: Array[ColorRect] = []
var active_index: int = -1
var _is_initialized: bool = false

# スロットに割り当てるピースタイプの定義
var _assignments: Array = [
	PieceData.Type.BEE,
	PieceData.Type.WORM,
	PieceData.Type.WAVE,
	PieceData.Type.PISTOL,
	PieceData.Type.BAR,
	PieceData.Type.PROPELLER,
	PieceData.Type.ARCH,
	PieceData.Type.CHEST
]

@onready var palette_container: HBoxContainer = $PaletteContainer


func _ready():
	if palette_container:
		_initialize_palette()


func setup(piece_placer_ref: PiecePlacer):
	piece_placer = piece_placer_ref
	if is_node_ready():
		_initialize_palette()


func _initialize_palette():
	if not palette_container:
		return

	_collect_slots()
	_refresh_slots()
	_is_initialized = true


func _collect_slots():
	slot_rects.clear()
	var slots = palette_container.get_children()
	for i in range(slots.size()):
		var rect = slots[i] as ColorRect
		if rect:
			slot_rects.append(rect)
			# シグナルがすでに接続されているかチェック（二重接続防止のクリーンな方法）
			if not rect.gui_input.is_connected(_on_slot_gui_input):
				rect.gui_input.connect(_on_slot_gui_input.bind(i))

			# アイコンを生成
			var piece_data = get_piece_data_for_slot(i)
			if piece_data:
				_create_piece_icon(rect, piece_data)


func _on_slot_gui_input(event: InputEvent, index: int):
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			select_slot(index)


func select_slot(index: int):
	if active_index == index:
		active_index = -1
		if piece_placer:
			piece_placer.select_piece(null)
	else:
		active_index = index
		if piece_placer:
			var data = get_piece_data_for_slot(active_index)
			piece_placer.select_piece(data)

	_refresh_slots()


func get_piece_data_for_slot(index: int) -> PieceData:
	if index < 0 or index >= _assignments.size():
		return null
	return PieceData.get_data(_assignments[index])


func _create_piece_icon(parent: Control, piece_data: PieceData):
	for child in parent.get_children():
		child.queue_free()

	var icon_root = Node2D.new()
	icon_root.name = "IconRoot"
	icon_root.position = parent.custom_minimum_size / 2.0
	icon_root.scale = Vector2(0.15, 0.15)
	parent.add_child(icon_root)

	var shape = piece_data.shape
	var color = piece_data.color
	var layout = Layout.new(Layout.layout_pointy, Vector2(42, 42), Vector2(0, 0))

	for hex in shape:
		var tile = HexTileScene.instantiate()
		icon_root.add_child(tile)
		tile.position = Layout.hex_to_pixel(layout, hex)
		tile.setup_hex(hex)
		tile.set_color(color)


func _refresh_slots():
	for i in range(slot_rects.size()):
		var rect := slot_rects[i]
		if rect:
			rect.color = active_color if i == active_index else inactive_color


func get_slot_count() -> int:
	return slot_rects.size()


func get_active_index() -> int:
	return active_index


func get_active_piece_data() -> PieceData:
	if active_index == -1:
		return null
	return get_piece_data_for_slot(active_index)
