class_name HUD
extends CanvasLayer

signal slot_selected(scene: PackedScene)
# 研究画面・アイテム選択パネルが開いた／閉じた
signal modal_changed
# ツールバーのボタンにマウスが乗った（盤面にはマウスの動きが届かなくなるので、ゴーストを隠すのに使う）
signal toolbar_hovered

enum Category { LOGISTICS, EXTRACTION, PROCESSING, STORAGE }

const RESEARCH_BUTTON_TEXT := "研究 [E]"
# カーソル付近のメッセージ（在庫不足など）を出しておく時間と、カーソルからのずらし幅
const CURSOR_MESSAGE_SECONDS := 1.5
const CURSOR_MESSAGE_OFFSET := Vector2(18, 14)
# ツールバーの下の段に並ぶジャンル。押すと、そのジャンルのスロットが上の段に出る
const CATEGORIES := [
	{"name": "物流", "icon": preload("res://assets/pieces/category_logistics.svg")},
	{"name": "採掘", "icon": preload("res://assets/pieces/category_extraction.svg")},
	{"name": "加工", "icon": preload("res://assets/pieces/category_processing.svg")},
	{"name": "倉庫", "icon": preload("res://assets/pieces/category_storage.svg")},
]
# 機械の切り替え先の名前。チェストは切り替えで共有範囲を選ぶ
const TIER_LABELS: Array[String] = ["T1", "T2"]
const CHEST_SCOPE_LABELS: Array[String] = ["Chunk", "Biome", "Planet"]
# ツールバーのスロット。並び順がそのままボタンの並びと番号になる。
#   key: 選ぶ数字キー / category: 属するジャンル（CATEGORIES の番号） / icon: ボタンのアイコン
#   variants: T キーで切り替えるピース（先頭が既定） / labels: 切り替え先の名前
const SLOTS := [
	{
		"key": KEY_1,
		"category": Category.LOGISTICS,
		"icon": preload("res://assets/pieces/conveyor.svg"),
		"variants": [preload("res://scenes/components/piece/conveyor.tscn")],
		"labels": [],
	},
	{
		"key": KEY_2,
		"category": Category.EXTRACTION,
		"icon": preload("res://assets/pieces/miner.svg"),
		"variants":
		[
			preload("res://scenes/components/piece/miner_t1.tscn"),
			preload("res://scenes/components/piece/miner_t2.tscn"),
		],
		"labels": TIER_LABELS,
	},
	{
		"key": KEY_3,
		"category": Category.PROCESSING,
		"icon": preload("res://assets/pieces/smelter.svg"),
		"variants":
		[
			preload("res://scenes/components/piece/smelter_t1.tscn"),
			preload("res://scenes/components/piece/smelter_t2.tscn"),
		],
		"labels": TIER_LABELS,
	},
	{
		"key": KEY_4,
		"category": Category.PROCESSING,
		"icon": preload("res://assets/pieces/assembler.svg"),
		"variants":
		[
			preload("res://scenes/components/piece/assembler_t1.tscn"),
			preload("res://scenes/components/piece/assembler_t2.tscn"),
		],
		"labels": TIER_LABELS,
	},
	{
		"key": KEY_5,
		"category": Category.PROCESSING,
		"icon": preload("res://assets/pieces/cutter.svg"),
		"variants":
		[
			preload("res://scenes/components/piece/cutter_t1.tscn"),
			preload("res://scenes/components/piece/cutter_t2.tscn"),
		],
		"labels": TIER_LABELS,
	},
	{
		"key": KEY_6,
		"category": Category.PROCESSING,
		"icon": preload("res://assets/pieces/mixer.svg"),
		"variants":
		[
			preload("res://scenes/components/piece/mixer_t1.tscn"),
			preload("res://scenes/components/piece/mixer_t2.tscn"),
		],
		"labels": TIER_LABELS,
	},
	{
		"key": KEY_7,
		"category": Category.LOGISTICS,
		"icon": preload("res://assets/pieces/bridge.svg"),
		"variants": [preload("res://scenes/components/piece/bridge.tscn")],
		"labels": [],
	},
	{
		"key": KEY_8,
		"category": Category.STORAGE,
		"icon": preload("res://assets/pieces/chest_in.svg"),
		"variants":
		[
			preload("res://scenes/components/piece/chest_in.tscn"),
			preload("res://scenes/components/piece/biome_chest_in.tscn"),
			preload("res://scenes/components/piece/planet_chest_in.tscn"),
		],
		"labels": CHEST_SCOPE_LABELS,
	},
	{
		"key": KEY_9,
		"category": Category.STORAGE,
		"icon": preload("res://assets/pieces/chest_out.svg"),
		"variants":
		[
			preload("res://scenes/components/piece/chest_out.tscn"),
			preload("res://scenes/components/piece/biome_chest_out.tscn"),
			preload("res://scenes/components/piece/planet_chest_out.tscn"),
		],
		"labels": CHEST_SCOPE_LABELS,
	},
	# 窯は t2 を作らない（docs/recipe_plan.md）。あとから足した機械なので末尾（キー 0）に置く
	{
		"key": KEY_0,
		"category": Category.PROCESSING,
		"icon": preload("res://assets/pieces/kiln.svg"),
		"variants": [preload("res://scenes/components/piece/kiln_t1.tscn")],
		"labels": [],
	},
]
const SLOT_BUTTON_SIZE := Vector2(52, 60)
const CATEGORY_BUTTON_SIZE := Vector2(44, 50)

var slot_buttons: Array = []
var category_buttons: Array = []
# スロットごとの、いま選んでいる切り替え先の番号
var _variant_indices: Array[int] = []
# シーン → ピースの種類（解放の判定に使う。シーンを毎回作らないよう覚えておく）
var _piece_types: Dictionary = {}

# マウスが乗っている設置済みピース（撤去されて無効になることがあるので型は付けない）
var _hovered_piece = null
var _cursor_message_time_left := 0.0
var _active_category := -1
# 設置するために選んでいるスロット。選んでいなければ -1。
# 選択の状態はここだけで持ち、ボタンの押された見た目はこれに合わせて描き直す
var _active_slot := -1

@onready var toolbar: VBoxContainer = $ToolBar
@onready var piece_row: HBoxContainer = $ToolBar/PieceRow
@onready var category_row: HBoxContainer = $ToolBar/CategoryRow
@onready var stock_display: StockDisplay = %StockDisplay
@onready var cursor_message: Label = %CursorMessage
@onready var research_button: Button = %ResearchButton
@onready var research_panel: ResearchPanel = %ResearchPanel
@onready var item_picker: ItemPicker = %ItemPicker
@onready var info_panel: PieceInfoPanel = $SidePanels/PieceInfoPanel
@onready var variant_panel: VariantPanel = $SidePanels/VariantPanel


func _ready():
	_build_toolbar()
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


# ツールバーのボタンを作る。上の段（PieceRow）に全スロットを並べ、開いているジャンルの分だけ見せる。
# 下の段（CategoryRow）はジャンルのボタン
func _build_toolbar() -> void:
	for i in SLOTS.size():
		_variant_indices.append(0)
		var btn := HexButton.new()
		btn.name = "Slot%d" % (i + 1)
		btn.custom_minimum_size = SLOT_BUTTON_SIZE
		btn.toggle_mode = true
		btn.hex_icon = SLOTS[i]["icon"]
		btn.hint = OS.get_keycode_string(SLOTS[i]["key"])
		btn.pressed.connect(select_slot.bind(i))
		_connect_toolbar_pointer(btn)
		piece_row.add_child(btn)
		slot_buttons.append(btn)
	for c in CATEGORIES.size():
		var btn := HexButton.new()
		btn.name = "Category%d" % (c + 1)
		btn.custom_minimum_size = CATEGORY_BUTTON_SIZE
		btn.toggle_mode = true
		btn.hex_icon = CATEGORIES[c]["icon"]
		btn.tooltip_text = CATEGORIES[c]["name"]
		btn.pressed.connect(_on_category_pressed.bind(c))
		_connect_toolbar_pointer(btn)
		category_row.add_child(btn)
		category_buttons.append(btn)
	_show_category(-1)


# ツールバーのボタンの上では、盤面と同じくマウスの右ボタンで選択を解除できるようにする
func _connect_toolbar_pointer(btn: Button) -> void:
	btn.mouse_entered.connect(func(): toolbar_hovered.emit())
	btn.gui_input.connect(_on_toolbar_gui_input)


func _on_toolbar_gui_input(event: InputEvent) -> void:
	var mouse := event as InputEventMouseButton
	if mouse and mouse.button_index == MOUSE_BUTTON_RIGHT and mouse.pressed:
		deselect()


func get_category_name(category_index: int) -> String:
	return CATEGORIES[category_index]["name"]


# 開いているジャンルの番号。どれも開いていなければ -1
func get_active_category() -> int:
	return _active_category


# ジャンルに属するスロットの番号（並び順）
func _slots_in_category(category_index: int) -> Array:
	var result := []
	for i in SLOTS.size():
		if SLOTS[i]["category"] == category_index:
			result.append(i)
	return result


# ジャンルのボタンを押した: 閉じていれば開き、開いていれば閉じる。
# 見えなくなるピースを選んだままにしないよう、選んでいたピースは解除する
func _on_category_pressed(category_index: int) -> void:
	var next := -1 if category_index == _active_category else category_index
	if get_active_index() != -1:
		deselect()
	_show_category(next)


func _show_category(category_index: int) -> void:
	_active_category = category_index
	var shown: Array = [] if category_index < 0 else _slots_in_category(category_index)
	for i in slot_buttons.size():
		slot_buttons[i].visible = i in shown
	piece_row.visible = category_index >= 0
	for c in category_buttons.size():
		category_buttons[c].set_pressed_no_signal(c == category_index)


# スロットを選ぶ（ボタンのクリック・数字キーはどちらもここを通る）。
# 選んでいなければ選び、そのスロットのジャンルを開く。選んでいれば選択を外す。未解放なら何もしない
func select_slot(index: int) -> void:
	if index < 0 or index >= slot_buttons.size():
		return
	if index == _active_slot:
		deselect()
		return
	if not _is_slot_unlocked(index):
		_sync_slot_buttons()
		return
	var category: int = SLOTS[index]["category"]
	if category != _active_category:
		_show_category(category)
	# ピースを選んだら研究画面は閉じる（説明パネルと重ならないように）
	research_panel.close()
	_reset_other_variant_indices(index)
	_active_slot = index
	_sync_slot_buttons()
	slot_selected.emit(get_scene_for_slot(index))


# 選択を解除する。解除はすべてここを通し、ボタンの見た目・切替パネル・説明を同じように片付ける
func deselect() -> void:
	_active_slot = -1
	_sync_slot_buttons()
	variant_panel.clear()
	slot_selected.emit(null)


# ボタンは押すと自分で押された見た目に切り替わるので、選択の状態に合わせて戻す
func _sync_slot_buttons() -> void:
	for i in slot_buttons.size():
		slot_buttons[i].set_pressed_no_signal(i == _active_slot)


# 数字キーでスロットを選ぶ。閉じているジャンルのボタンも選べるよう、ボタンのショートカットではなくここで受ける
func _shortcut_input(event: InputEvent) -> void:
	if not visible or not event is InputEventKey:
		return
	var key := event as InputEventKey
	if not key.pressed or key.echo or key.ctrl_pressed or key.alt_pressed or key.meta_pressed:
		return
	var index := -1
	for i in SLOTS.size():
		if SLOTS[i]["key"] == key.keycode:
			index = i
	if index == -1:
		return
	select_slot(index)
	get_viewport().set_input_as_handled()


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
		var unlocked := _is_slot_unlocked(i)
		btn.disabled = not unlocked
		btn.modulate = Color(1, 1, 1, 1) if unlocked else Color(0.4, 0.4, 0.4, 1)
	# 中のピースがひとつも解放されていないジャンルは押せない
	for c in category_buttons.size():
		var any_unlocked := false
		for i in _slots_in_category(c):
			any_unlocked = any_unlocked or not slot_buttons[i].disabled
		category_buttons[c].disabled = not any_unlocked
		category_buttons[c].modulate = Color.WHITE if any_unlocked else Color(0.4, 0.4, 0.4, 1)


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
	var variants: Array = SLOTS[slot_index]["variants"]
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
	return SLOTS[slot_index]["labels"][variant_index]


# スロットの既定のピース（先頭の切り替え先）が解放済みか
func _is_slot_unlocked(slot_index: int) -> bool:
	return _is_scene_unlocked(SLOTS[slot_index]["variants"][0])


# 切り替え先のピースが解放済みか（同じスロットでも、上位のチェストは別の研究で解放する）
func _is_scene_unlocked(scene: PackedScene) -> bool:
	if not _piece_types.has(scene):
		var piece = scene.instantiate()
		_piece_types[scene] = piece.piece_type
		piece.free()
	return PieceData.is_unlocked(_piece_types[scene])


func _select_variant(slot_index: int, variant_index: int) -> void:
	if not _is_scene_unlocked(SLOTS[slot_index]["variants"][variant_index]):
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


# 機械は先頭のレシピで止まらずに動いたときの速さ（設置前なので鉱床の濃さは含めない）。
# 計算は置いたあとの機械と同じ Crafter に任せる（研究の効果や機械の倍率を含む）。
# コンベアは TransferBuffer の搬送間隔から算出。
func _items_per_minute_for_piece(piece: Node) -> float:
	var piece_type: PieceData.Type = piece.piece_type
	var recipes = Recipe.RecipeDB.get_recipes_by_type(piece_type)
	# piece は説明を出すためだけに作った木の外のピースで、型付きの部品の参照（@onready）はまだ空なので名前で取る
	var crafter := piece.get_node_or_null("Crafter") as Crafter
	if crafter and not recipes.is_empty():
		crafter.is_miner = piece_type == PieceData.Type.MINER
		crafter.set_recipe(recipes[0])
		return crafter.get_max_items_per_minute()
	if piece_type == PieceData.Type.CONVEYOR:
		return HubGoals.get_belt_items_per_minute()
	return 0.0


func _reset_other_variant_indices(active_index: int) -> void:
	for i in _variant_indices.size():
		if i != active_index:
			_variant_indices[i] = 0


func get_scene_for_slot(index: int) -> PackedScene:
	if index < 0 or index >= SLOTS.size():
		return null
	return SLOTS[index]["variants"][_variant_indices[index]]


func cycle_variant() -> void:
	var index = get_active_index()
	if index < 0:
		return
	var variants: Array = SLOTS[index]["variants"]
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


func set_chunk_coordinate(chunk_hex: Vector2i) -> void:
	$ChunkCoordLabel.text = "Chunk: %d, %d" % [chunk_hex.x, chunk_hex.y]


func get_active_index() -> int:
	return _active_slot
