class_name HUD
extends CanvasLayer

signal slot_selected(scene: PackedScene)
# 研究画面・アイテム選択パネルが開いた／閉じた
signal modal_changed

const CONVEYOR_SCENE = preload("res://scenes/components/piece/conveyor.tscn")
const MINER_T1_SCENE = preload("res://scenes/components/piece/miner_t1.tscn")
const MINER_T2_SCENE = preload("res://scenes/components/piece/miner_t2.tscn")
const SMELTER_T1_SCENE = preload("res://scenes/components/piece/smelter_t1.tscn")
const SMELTER_T2_SCENE = preload("res://scenes/components/piece/smelter_t2.tscn")
const ASSEMBLER_T1_SCENE = preload("res://scenes/components/piece/assembler_t1.tscn")
const ASSEMBLER_T2_SCENE = preload("res://scenes/components/piece/assembler_t2.tscn")
const CUTTER_T1_SCENE = preload("res://scenes/components/piece/cutter_t1.tscn")
const CUTTER_T2_SCENE = preload("res://scenes/components/piece/cutter_t2.tscn")
const MIXER_T1_SCENE = preload("res://scenes/components/piece/mixer_t1.tscn")
const MIXER_T2_SCENE = preload("res://scenes/components/piece/mixer_t2.tscn")
const PAINTER_SCENE = preload("res://scenes/components/piece/painter.tscn")
const SENDER_SCENE = preload("res://scenes/components/piece/sender.tscn")
const RECEIVER_SCENE = preload("res://scenes/components/piece/receiver.tscn")
const CHEST_IN_SCENE = preload("res://scenes/components/piece/chest_in.tscn")
const CHEST_OUT_SCENE = preload("res://scenes/components/piece/chest_out.tscn")
const BIOME_CHEST_IN_SCENE = preload("res://scenes/components/piece/biome_chest_in.tscn")
const BIOME_CHEST_OUT_SCENE = preload("res://scenes/components/piece/biome_chest_out.tscn")
const PLANET_CHEST_IN_SCENE = preload("res://scenes/components/piece/planet_chest_in.tscn")
const PLANET_CHEST_OUT_SCENE = preload("res://scenes/components/piece/planet_chest_out.tscn")
# チェストのスロットは、切り替えで共有範囲を選ぶ（機械のスロットは T1/T2）
const CHEST_VARIANT_LABELS: Array[String] = ["Chunk", "Biome", "Planet"]
const CHEST_SLOTS := [9, 10]
const RESEARCH_BUTTON_TEXT := "研究 [E]"
# カーソル付近のメッセージ（在庫不足など）を出しておく時間と、カーソルからのずらし幅
const CURSOR_MESSAGE_SECONDS := 1.5
const CURSOR_MESSAGE_OFFSET := Vector2(18, 14)
var _slot_variants: Array = [
	[CONVEYOR_SCENE],
	[MINER_T1_SCENE, MINER_T2_SCENE],
	[SMELTER_T1_SCENE, SMELTER_T2_SCENE],
	[ASSEMBLER_T1_SCENE, ASSEMBLER_T2_SCENE],
	[CUTTER_T1_SCENE, CUTTER_T2_SCENE],
	[MIXER_T1_SCENE, MIXER_T2_SCENE],
	[PAINTER_SCENE],
	[SENDER_SCENE],
	[RECEIVER_SCENE],
	[CHEST_IN_SCENE, BIOME_CHEST_IN_SCENE, PLANET_CHEST_IN_SCENE],
	[CHEST_OUT_SCENE, BIOME_CHEST_OUT_SCENE, PLANET_CHEST_OUT_SCENE],
]
var _variant_indices: Array[int] = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]

var _scene_types: Array[PieceData.Type] = [
	PieceData.Type.CONVEYOR,
	PieceData.Type.MINER,
	PieceData.Type.SMELTER,
	PieceData.Type.ASSEMBLER,
	PieceData.Type.CUTTER,
	PieceData.Type.MIXER,
	PieceData.Type.PAINTER,
	PieceData.Type.SENDER,
	PieceData.Type.RECEIVER,
	PieceData.Type.CHEST,
	PieceData.Type.CHEST_OUT,
]

# マウスが乗っている設置済みピース（撤去されて無効になることがあるので型は付けない）
var _hovered_piece = null
var _cursor_message_time_left := 0.0

@onready var toolbar: HBoxContainer = $ToolBar
@onready var slot_buttons: Array = $ToolBar.get_children()
@onready var stock_display: StockDisplay = %StockDisplay
@onready var cursor_message: Label = %CursorMessage
@onready var research_button: Button = %ResearchButton
@onready var research_panel: ResearchPanel = %ResearchPanel
@onready var item_picker: ItemPicker = %ItemPicker
@onready var info_panel: PieceInfoPanel = $SidePanels/PieceInfoPanel
@onready var variant_panel: VariantPanel = $SidePanels/VariantPanel
@onready var _button_group: ButtonGroup = (
	(slot_buttons[0] as Button).button_group if not slot_buttons.is_empty() else null
)


func _ready():
	info_panel.clear()
	slot_selected.connect(_on_slot_selected_for_info)
	HubGoals.level_up.connect(_on_level_up)
	HubGoals.unlocks_changed.connect(_refresh_unlock_states)
	HubGoals.stock_changed.connect(_on_stock_changed)
	HubGoals.research_changed.connect(_refresh_research_button)
	research_button.pressed.connect(toggle_research_panel)
	research_panel.visibility_changed.connect(func(): modal_changed.emit())
	item_picker.visibility_changed.connect(func(): modal_changed.emit())
	_refresh_research_button()
	_refresh_unlock_states()


func _on_stock_changed() -> void:
	_refresh_research_button()
	# 選んでいるピースの「在庫不足」の表示を最新にする
	var scene = get_scene_for_slot(get_active_index())
	if scene:
		_show_selected_info(scene)


# カーソルの近くに短いメッセージを出す（在庫不足で設置できなかったときなど）。
# screen_position は画面上のマウス位置。しばらくすると自動で消える。
func show_cursor_message(text: String, screen_position: Vector2) -> void:
	cursor_message.text = text
	cursor_message.position = screen_position + CURSOR_MESSAGE_OFFSET
	cursor_message.visible = true
	_cursor_message_time_left = CURSOR_MESSAGE_SECONDS


# ホバー中のピースの状態は刻々と変わるので、毎フレーム表示を更新する
func _process(delta: float) -> void:
	if _hovered_piece != null:
		_refresh_hover_info()
	if cursor_message.visible:
		_cursor_message_time_left -= delta
		if _cursor_message_time_left <= 0.0:
			cursor_message.visible = false


# 研究画面を開閉する。開くときは盤面の操作をやめる:
# 選んでいたピースを解除し、ピースの説明・ホバー情報・アイテム選択パネルを消す
# （研究画面と右上の説明パネルが重なって読みにくくなるのを防ぐ）。
func toggle_research_panel() -> void:
	if not research_panel.visible:
		item_picker.close()
		_hovered_piece = null
		deselect()
		info_panel.clear()
	research_panel.toggle()


# 研究画面かアイテム選択パネルが開いているか（開いている間は盤面を操作させない）
func is_modal_open() -> bool:
	return research_panel.visible or item_picker.visible


func close_modals() -> void:
	research_panel.close()
	item_picker.close()


# 搬出チェストが取り出すアイテムを選ぶパネルを開く（搬出チェスト以外では何もしない）
func open_item_picker(piece: Piece) -> void:
	item_picker.open(piece)


# 設置済みピースにマウスが乗ったら、そのピースの状態を情報パネルに出す。null で解除。
func show_hovered_piece(piece: Piece) -> void:
	# 研究画面を開いている間は、説明パネルを出さない
	_hovered_piece = null if research_panel.visible else piece
	_refresh_hover_info()


func _refresh_hover_info() -> void:
	# 設置するピースを選んでいる間は、選んだピースの説明を優先する
	if get_active_index() != -1:
		return
	if not is_instance_valid(_hovered_piece) or _hovered_piece.is_queued_for_deletion():
		_hovered_piece = null
		info_panel.clear()
		return
	info_panel.show_info(
		_hovered_piece.piece_name,
		PieceStatus.describe(_hovered_piece),
		PieceStatus.rate_text(_hovered_piece)
	)


func _on_level_up(_new_level: int, _reward: String):
	_refresh_unlock_states()
	_refresh_research_button()


# いま研究できるものがあれば、その件数をボタンに出して気づけるようにする
func _refresh_research_button() -> void:
	var available := 0
	for id in Research.all_ids():
		if HubGoals.research_state(id) == Research.State.AVAILABLE:
			available += 1
	research_button.text = RESEARCH_BUTTON_TEXT
	if available > 0:
		research_button.text += " (%d)" % available


func _refresh_unlock_states():
	for i in slot_buttons.size():
		var btn := slot_buttons[i] as Button
		if btn == null:
			continue
		var unlocked := PieceData.is_unlocked(_scene_types[i])
		btn.disabled = not unlocked
		btn.modulate = Color(1, 1, 1, 1) if unlocked else Color(0.4, 0.4, 0.4, 1)


func _on_slot_selected_for_info(scene: PackedScene):
	if scene == null:
		_refresh_hover_info()
		return
	_show_selected_info(scene)
	var slot_index = get_active_index()
	_refresh_variant_row(slot_index)


func _show_selected_info(scene: PackedScene) -> void:
	var piece = scene.instantiate()
	var description = "%s\n%s" % [piece.piece_description, _cost_text(scene)]
	info_panel.show_info(piece.piece_name, description.strip_edges(), _rate_text_for_piece(piece))
	piece.free()


func _cost_text(scene: PackedScene) -> String:
	var cost = BuildCost.of_scene(scene)
	var text = "コスト: %s" % BuildCost.to_text(cost)
	if not HubGoals.can_afford(cost):
		text += "（在庫不足）"
	return text


func _refresh_variant_row(slot_index: int) -> void:
	if slot_index < 0:
		variant_panel.clear()
		return
	var variants: Array = _slot_variants[slot_index]
	if variants.size() <= 1:
		variant_panel.clear()
		return
	var labels: Array[String] = []
	var locked: Array = []
	for i in variants.size():
		labels.append(_variant_label(slot_index, i))
		if not _is_scene_unlocked(variants[i]):
			locked.append(i)
	variant_panel.show_variants(
		labels, _variant_indices[slot_index], func(vi: int): _select_variant(slot_index, vi), locked
	)


func _variant_label(slot_index: int, variant_index: int) -> String:
	if slot_index in CHEST_SLOTS:
		return CHEST_VARIANT_LABELS[variant_index]
	return "T%d" % (variant_index + 1)


# 切り替え先のピースが解放済みか（同じスロットでも、上位のチェストは別の研究で解放する）
func _is_scene_unlocked(scene: PackedScene) -> bool:
	var piece = scene.instantiate()
	var unlocked = PieceData.is_unlocked(piece.piece_type)
	piece.free()
	return unlocked


func _select_variant(slot_index: int, variant_index: int) -> void:
	if not _is_scene_unlocked(_slot_variants[slot_index][variant_index]):
		_refresh_variant_row(slot_index)
		return
	_variant_indices[slot_index] = variant_index
	slot_selected.emit(get_scene_for_slot(slot_index))


# ピースの実効速度（個/分）を表示用テキストにする。速度を持たないピースは空文字。
func _rate_text_for_piece(piece: Node) -> String:
	var rate = _items_per_minute_for_piece(piece)
	if rate <= 0.0:
		return ""
	return "スピード: %d/分" % roundi(rate)


# 機械はレシピ速度÷craft_time_multiplier、コンベアは TransferBuffer の搬送間隔から算出。
func _items_per_minute_for_piece(piece: Node) -> float:
	var piece_type: PieceData.Type = piece.piece_type
	var recipes = Recipe.RecipeDB.get_recipes_by_type(piece_type)
	if not recipes.is_empty():
		var crafter = piece.get_node_or_null("Crafter")
		var multiplier: float = crafter.craft_time_multiplier if crafter else 1.0
		return recipes[0].items_per_minute() / multiplier
	if piece_type == PieceData.Type.CONVEYOR:
		return 60.0 / TransferBuffer.TRANSFER_TIME * HubGoals.get_belt_speed()
	return 0.0


func on_slot_pressed(index: int):
	if index < 0 or index >= slot_buttons.size():
		_deselect_all_buttons()
		slot_selected.emit(null)
		return

	# ピースを選んだら研究画面は閉じる（説明パネルと重ならないように）
	research_panel.close()
	_reset_other_variant_indices(index)
	var btn = slot_buttons[index]
	if btn.button_pressed:
		slot_selected.emit(get_scene_for_slot(index))
	else:
		slot_selected.emit(null)


func _reset_other_variant_indices(active_index: int) -> void:
	for i in _variant_indices.size():
		if i != active_index:
			_variant_indices[i] = 0


func _deselect_all_buttons():
	if _button_group and _button_group.get_pressed_button():
		_button_group.get_pressed_button().button_pressed = false


func get_scene_for_slot(index: int) -> PackedScene:
	if index < 0 or index >= _slot_variants.size():
		return null
	var variants: Array = _slot_variants[index]
	return variants[_variant_indices[index]]


func cycle_variant() -> void:
	var index = get_active_index()
	if index < 0:
		return
	var variants: Array = _slot_variants[index]
	if variants.size() <= 1:
		return
	# 未研究の切り替え先は飛ばして、次に使えるものへ進む
	var next = _variant_indices[index]
	for _step in variants.size():
		next = (next + 1) % variants.size()
		if _is_scene_unlocked(variants[next]):
			break
	_variant_indices[index] = next
	_refresh_variant_row(index)
	slot_selected.emit(get_scene_for_slot(index))


func deselect():
	_deselect_all_buttons()
	variant_panel.clear()
	slot_selected.emit(null)


func set_chunk_coordinate(chunk_hex: Hex) -> void:
	$ChunkCoordLabel.text = "Chunk: %d, %d" % [chunk_hex.q, chunk_hex.r]


func get_active_index() -> int:
	if not _button_group:
		return -1
	var pressed_btn = _button_group.get_pressed_button()
	return pressed_btn.get_index() if pressed_btn else -1
