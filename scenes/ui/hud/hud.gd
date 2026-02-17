class_name HUD
extends CanvasLayer

const HexTileScene = preload("res://scenes/components/hex_tile/hex_tile.tscn")

var piece_placer: PiecePlacer

var slot_buttons: Array[Button] = []
var active_index: int = -1
var _is_initialized: bool = false

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

@onready var toolbar: HBoxContainer = $ToolBar


func _ready():
	if toolbar:
		_initialize_toolbar()


func setup(piece_placer_ref: PiecePlacer):
	piece_placer = piece_placer_ref
	if is_node_ready():
		_initialize_toolbar()


func _initialize_toolbar():
	if not toolbar:
		return

	_collect_slots()
	_is_initialized = true


func _collect_slots():
	slot_buttons.clear()
	var slots = toolbar.get_children()
	for i in range(slots.size()):
		var btn = slots[i] as Button
		if btn:
			slot_buttons.append(btn)
			if not btn.pressed.is_connected(_on_slot_pressed):
				btn.pressed.connect(_on_slot_pressed.bind(i))

			# アイコンを生成
			var piece_data = get_piece_data_for_slot(i)
			if piece_data:
				_create_piece_icon(btn, piece_data)


func _on_slot_pressed(index: int):
	select_slot(index)


func select_slot(index: int):
	# 以前の選択があるならフォーカスを外す（ハイライト除去）
	if active_index >= 0:
		slot_buttons[active_index].release_focus()

	if active_index == index or index == -1:
		# 解除
		active_index = -1
		if piece_placer:
			piece_placer.select_piece(null)
	else:
		# 選択
		active_index = index
		if piece_placer:
			var data = get_piece_data_for_slot(active_index)
			piece_placer.select_piece(data)


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


func get_slot_count() -> int:
	return slot_buttons.size()


func get_active_index() -> int:
	return active_index


func get_active_piece_data() -> PieceData:
	if active_index == -1:
		return null
	return get_piece_data_for_slot(active_index)
