class_name ResearchPanel
extends PanelContainer

## 研究の一覧。在庫を払って研究を進める画面。
## 行は Research の定義から作り、在庫・レベル・研究の変化に合わせて表示を更新する。

const PANEL_SIZE := Vector2(520, 0)
# 研究が増えても画面からはみ出さないよう、一覧はこの高さでスクロールさせる
const LIST_HEIGHT := 400.0
const TITLE_TEXT := "研究"
const BUTTON_TEXT := "研究する"

var _buttons: Dictionary = {}  # research_id → Button
var _status_labels: Dictionary = {}  # research_id → Label
var _info_labels: Dictionary = {}  # research_id → Label


func _ready() -> void:
	visible = false
	custom_minimum_size = PANEL_SIZE
	_build()
	HubGoals.research_changed.connect(refresh)
	HubGoals.stock_changed.connect(refresh)
	HubGoals.level_up.connect(func(_level, _reward): refresh())
	refresh()


func toggle() -> void:
	visible = not visible
	if visible:
		refresh()


func get_button(id: String) -> Button:
	return _buttons.get(id)


func get_status_text(id: String) -> String:
	return _status_labels[id].text


# その研究の行に表示されている文章（名前・説明・価格）
func get_row_text(id: String) -> String:
	return _info_labels[id].text


func refresh() -> void:
	for id in _buttons:
		var state = HubGoals.research_state(id)
		_buttons[id].disabled = state != Research.State.AVAILABLE
		_status_labels[id].text = HubGoals.research_state_text(id)


func _build() -> void:
	var margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 16)
	add_child(margin)
	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 10)
	margin.add_child(layout)
	var title := Label.new()
	title.text = TITLE_TEXT
	title.add_theme_font_size_override("font_size", 22)
	layout.add_child(title)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(0, LIST_HEIGHT)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	layout.add_child(scroll)
	var rows := VBoxContainer.new()
	rows.add_theme_constant_override("separation", 10)
	rows.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(rows)
	for id in Research.all_ids():
		rows.add_child(_build_row(id))


func _build_row(id: String) -> Control:
	var def = Research.get_def(id)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)

	var info := Label.new()
	info.text = (
		"%s\n%s\n価格: %s" % [def["name"], def["description"], BuildCost.to_text(def["cost"])]
	)
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(info)
	_info_labels[id] = info

	var side := VBoxContainer.new()
	side.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_child(side)
	var button := Button.new()
	button.text = BUTTON_TEXT
	button.custom_minimum_size = Vector2(110, 36)
	button.pressed.connect(func(): HubGoals.research(id))
	side.add_child(button)
	_buttons[id] = button
	var status := Label.new()
	status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status.add_theme_font_size_override("font_size", 12)
	side.add_child(status)
	_status_labels[id] = status
	return row
