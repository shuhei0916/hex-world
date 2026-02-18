class_name HUD
extends CanvasLayer

const HexTileScene = preload("res://scenes/components/hex_tile/hex_tile.tscn")

var piece_placer: PiecePlacer

# スロット管理 (テストアクセスのためパブリックに維持)
var slot_buttons: Array[Button] = []

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

	_setup_toolbar_slots()


func _setup_toolbar_slots():
	slot_buttons.clear()
	var slots = toolbar.get_children()

	for i in range(slots.size()):
		var btn = slots[i] as Button
		if btn:
			slot_buttons.append(btn)

			# シグナル接続（重複防止）
			if not btn.pressed.is_connected(_on_slot_pressed):
				btn.pressed.connect(_on_slot_pressed.bind(i))

			# アイコンを生成
			var piece_data = get_piece_data_for_slot(i)
			if piece_data:
				_create_piece_icon(btn, piece_data)


func _on_slot_pressed(index: int):
	var btn = slot_buttons[index]

	if btn.button_pressed:
		_select_piece(index)
	else:
		_deselect_piece()


func _select_piece(index: int):
	if piece_placer:
		var data = get_piece_data_for_slot(index)
		piece_placer.select_piece(data)


func _deselect_piece():
	if piece_placer:
		piece_placer.select_piece(null)


# 外部からの操作用（キー入力や右クリック解除など）
func select_slot(index: int):
	if index < 0 or index >= slot_buttons.size():
		# インデックス外（-1など）は現在の選択を解除
		var group = _get_button_group()
		if group:
			var pressed_btn = group.get_pressed_button()
			if pressed_btn:
				pressed_btn.button_pressed = false
		_deselect_piece()
		return

	var btn = slot_buttons[index]
	# ToggleModeがONの前提。button_pressedを反転させると自動的にグループ内の他が解除される
	btn.button_pressed = not btn.button_pressed
	_on_slot_pressed(index)


func get_piece_data_for_slot(index: int) -> PieceData:
	if index < 0 or index >= _assignments.size():
		return null
	return PieceData.get_data(_assignments[index])


func _create_piece_icon(parent: Control, piece_data: PieceData):
	# 既存のアイコンがあれば削除
	for child in parent.get_children():
		if child.name == "IconRoot":
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
	var group = _get_button_group()
	if not group:
		# グループがない場合はボタンを直接調べる
		for i in range(slot_buttons.size()):
			if slot_buttons[i].button_pressed:
				return i
		return -1
	var pressed_btn = group.get_pressed_button()
	if not pressed_btn:
		return -1
	return slot_buttons.find(pressed_btn)


func get_active_piece_data() -> PieceData:
	var index = get_active_index()
	if index == -1:
		return null
	return get_piece_data_for_slot(index)


# ヘルパー: ボタンからグループを取得
func _get_button_group() -> ButtonGroup:
	if not slot_buttons.is_empty():
		return slot_buttons[0].button_group
	return null
