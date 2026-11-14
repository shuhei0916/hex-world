class_name ResearchPanel
extends PanelContainer

## 研究の一覧。在庫を払って研究を進める画面。
## 行は Research の定義から作り、在庫・レベル・研究の変化に合わせて表示を更新する。
## 研究できるものを上に、研究済みのものを下に並べ替える。

const PANEL_SIZE := Vector2(560, 0)
# 研究が増えても画面からはみ出さないよう、一覧はこの高さでスクロールさせる
const LIST_HEIGHT := 420.0
const TITLE_TEXT := "研究"
const HINT_TEXT := "E キーで閉じる"
const BUTTON_TEXT := "研究する"
const DONE_ALPHA := 0.5

# 後ろのマップが透けて読みにくくならないよう、背景はほぼ不透明にする
const BACKGROUND_COLOR := Color(0.09, 0.1, 0.13, 0.98)
const BORDER_COLOR := Color(0.45, 0.5, 0.6)
const ROW_COLOR := Color(0.16, 0.18, 0.23)
const NAME_COLOR := Color(1, 1, 1)
const DESCRIPTION_COLOR := Color(0.72, 0.75, 0.8)
const AFFORDABLE_COLOR := Color(0.55, 0.9, 0.55)
const UNAFFORDABLE_COLOR := Color(1.0, 0.55, 0.5)
const STATUS_COLOR := Color(1.0, 0.82, 0.45)

# 一覧に並べる順（小さいほど上）
const STATE_ORDER = {
	Research.State.AVAILABLE: 0,
	Research.State.UNAFFORDABLE: 1,
	Research.State.LOCKED_PREREQUISITE: 2,
	Research.State.LOCKED_LEVEL: 3,
	Research.State.DONE: 4,
}

var close_button: Button

var _rows_container: VBoxContainer
var _rows: Dictionary = {}  # research_id → 行の Control
var _buttons: Dictionary = {}  # research_id → Button
var _name_labels: Dictionary = {}  # research_id → Label
var _description_labels: Dictionary = {}  # research_id → Label
var _cost_labels: Dictionary = {}  # research_id → Label
var _status_labels: Dictionary = {}  # research_id → Label


func _ready() -> void:
	visible = false
	custom_minimum_size = PANEL_SIZE
	add_theme_stylebox_override("panel", _make_box(BACKGROUND_COLOR, BORDER_COLOR, 2, 10))
	_build()
	HubGoals.research_changed.connect(refresh)
	HubGoals.stock_changed.connect(refresh)
	HubGoals.level_up.connect(func(_level, _reward): refresh())
	refresh()


func toggle() -> void:
	visible = not visible
	if visible:
		refresh()


func close() -> void:
	visible = false


func get_button(id: String) -> Button:
	return _buttons.get(id)


func get_row(id: String) -> Control:
	return _rows.get(id)


func get_status_text(id: String) -> String:
	return _status_labels[id].text


# その研究の行に表示されている文章（名前・説明・価格）
func get_row_text(id: String) -> String:
	return (
		"%s\n%s\n%s" % [_name_labels[id].text, _description_labels[id].text, _cost_labels[id].text]
	)


# いま表示されている並び順の研究 id
func get_row_order() -> Array:
	var order := []
	for row in _rows_container.get_children():
		order.append(_rows.find_key(row))
	return order


func refresh() -> void:
	for id in _buttons:
		var state = HubGoals.research_state(id)
		_buttons[id].disabled = state != Research.State.AVAILABLE
		_status_labels[id].text = HubGoals.research_state_text(id)
		_rows[id].modulate.a = DONE_ALPHA if state == Research.State.DONE else 1.0
		_refresh_cost(id, state)
	_sort_rows()


# 価格は「手持ち/必要数」で示し、足りているかどうかで色を変える
func _refresh_cost(id: String, state: Research.State) -> void:
	var cost: Dictionary = Research.get_def(id)["cost"]
	var parts: Array[String] = []
	for item_id in cost:
		var item = ItemDB.get_item(item_id)
		var item_name = item.display_name if item else item_id
		parts.append("%s %d/%d" % [item_name, HubGoals.get_stock(item_id), cost[item_id]])
	var label: Label = _cost_labels[id]
	label.text = "価格: " + "、".join(parts)
	var color = AFFORDABLE_COLOR if HubGoals.can_afford(cost) else UNAFFORDABLE_COLOR
	if state == Research.State.DONE:
		color = DESCRIPTION_COLOR
	label.add_theme_color_override("font_color", color)


# 研究できるものを上へ。同じ状態のものは定義の順を保つ
func _sort_rows() -> void:
	var ids = Research.all_ids()
	var sorted_ids = ids.duplicate()
	sorted_ids.sort_custom(
		func(a, b):
			var order_a = STATE_ORDER[HubGoals.research_state(a)]
			var order_b = STATE_ORDER[HubGoals.research_state(b)]
			if order_a != order_b:
				return order_a < order_b
			return ids.find(a) < ids.find(b)
	)
	for i in sorted_ids.size():
		_rows_container.move_child(_rows[sorted_ids[i]], i)


func _build() -> void:
	var margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 18)
	add_child(margin)
	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 12)
	margin.add_child(layout)
	layout.add_child(_build_header())
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(0, LIST_HEIGHT)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	layout.add_child(scroll)
	_rows_container = VBoxContainer.new()
	_rows_container.add_theme_constant_override("separation", 8)
	_rows_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_rows_container)
	for id in Research.all_ids():
		_rows_container.add_child(_build_row(id))


func _build_header() -> Control:
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 12)
	var title := _make_label(TITLE_TEXT, 24, NAME_COLOR)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	header.add_child(_make_label(HINT_TEXT, 13, DESCRIPTION_COLOR))
	close_button = Button.new()
	close_button.text = "×"
	close_button.custom_minimum_size = Vector2(32, 32)
	close_button.focus_mode = Control.FOCUS_NONE
	close_button.pressed.connect(close)
	header.add_child(close_button)
	return header


func _build_row(id: String) -> Control:
	var def = Research.get_def(id)
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", _make_box(ROW_COLOR, ROW_COLOR, 0, 6))
	_rows[id] = card
	var margin := MarginContainer.new()
	for side in ["left", "right"]:
		margin.add_theme_constant_override("margin_" + side, 12)
	for side in ["top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 8)
	card.add_child(margin)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	margin.add_child(row)

	var info := VBoxContainer.new()
	info.add_theme_constant_override("separation", 2)
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(info)
	_name_labels[id] = _make_label(def["name"], 17, NAME_COLOR)
	_description_labels[id] = _make_label(def["description"], 13, DESCRIPTION_COLOR)
	_description_labels[id].autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_cost_labels[id] = _make_label("", 13, AFFORDABLE_COLOR)
	for label in [_name_labels[id], _description_labels[id], _cost_labels[id]]:
		info.add_child(label)

	var side_box := VBoxContainer.new()
	side_box.alignment = BoxContainer.ALIGNMENT_CENTER
	side_box.custom_minimum_size = Vector2(150, 0)
	row.add_child(side_box)
	var button := Button.new()
	button.text = BUTTON_TEXT
	button.custom_minimum_size = Vector2(120, 36)
	button.focus_mode = Control.FOCUS_NONE
	button.pressed.connect(func(): HubGoals.research(id))
	side_box.add_child(button)
	_buttons[id] = button
	var status := _make_label("", 12, STATUS_COLOR)
	status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	side_box.add_child(status)
	_status_labels[id] = status
	return card


func _make_label(text: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label


func _make_box(background: Color, border: Color, border_width: int, radius: int) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = background
	box.border_color = border
	box.set_border_width_all(border_width)
	box.set_corner_radius_all(radius)
	return box
