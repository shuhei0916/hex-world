class_name ResearchPanel
extends PanelContainer

## 研究ツリーの画面。在庫を払って研究を進める。
## 研究を六角形のノード（ResearchNode）で、行=系統・列=研究できるようになるハブのレベルに並べ
## （配置は ResearchTreeLayout）、前提の研究と線でつなぐ。ノードを選ぶと、右の詳細に
## 説明・価格・状態と「研究する」ボタンが出る。在庫・レベル・研究の変化に合わせて表示を更新する。

const TITLE_TEXT := "研究"
const HINT_TEXT := "E キーで閉じる"
const BUTTON_TEXT := "研究する"

# ツリーのマスの大きさ。ノードはマスの中央に置く
const COLUMN_WIDTH := 104.0
const ROW_HEIGHT := 96.0
const HEADER_HEIGHT := 28.0
const ROW_TITLE_WIDTH := 76.0
# ツリーが大きくなっても画面からはみ出さないよう、この大きさを超えたらスクロールさせる
const TREE_VIEW_MAX := Vector2(920, 430)
const DETAIL_WIDTH := 250.0
const LINK_WIDTH := 3.0

# 後ろのマップが透けて読みにくくならないよう、背景は不透明にする
const BACKGROUND_COLOR := Color(0.09, 0.1, 0.13, 1.0)
const BORDER_COLOR := Color(0.45, 0.5, 0.6)
const DETAIL_COLOR := Color(0.13, 0.15, 0.19)
const BAND_COLOR := Color(1, 1, 1, 0.03)
const NAME_COLOR := Color(1, 1, 1)
const DESCRIPTION_COLOR := Color(0.72, 0.75, 0.8)
const TITLE_COLOR := Color(0.55, 0.6, 0.68)
const AFFORDABLE_COLOR := Color(0.55, 0.9, 0.55)
const UNAFFORDABLE_COLOR := Color(1.0, 0.55, 0.5)
const STATUS_COLOR := Color(1.0, 0.82, 0.45)
const LINK_COLOR := Color("#3c4452")
const LINK_DONE_COLOR := Color("#4fa3d9")

var close_button: Button
var research_button: Button

var _canvas: Control
var _nodes: Dictionary = {}  # research_id → ResearchNode
var _links: Array = []  # [前提の id, 研究の id]
var _column_titles: Array[String] = []
var _row_titles: Array[String] = []
var _selected := ""
var _name_label: Label
var _description_label: Label
var _cost_label: Label
var _status_label: Label


func _ready() -> void:
	visible = false
	add_theme_stylebox_override("panel", _make_box(BACKGROUND_COLOR, BORDER_COLOR, 2, 10))
	_build()
	HubGoals.research_changed.connect(refresh)
	HubGoals.stock_changed.connect(refresh)
	HubGoals.exploration_changed.connect(refresh)
	HubGoals.level_up.connect(func(_level, _reward): refresh())
	select(_default_selection())


func toggle() -> void:
	visible = not visible
	if visible:
		select(_default_selection())


func close() -> void:
	visible = false


func get_node_button(id: String) -> ResearchNode:
	return _nodes.get(id)


# ツリーの中でのノードの六角形の中心
func get_node_center(id: String) -> Vector2:
	return _nodes[id].position + ResearchNode.HEX_CENTER


func get_links() -> Array:
	return _links


func get_link_color(from_id: String, _to_id: String) -> Color:
	return LINK_DONE_COLOR if HubGoals.is_researched(from_id) else LINK_COLOR


func get_column_titles() -> Array[String]:
	return _column_titles


func get_row_titles() -> Array[String]:
	return _row_titles


func get_selected() -> String:
	return _selected


func select(id: String) -> void:
	_selected = id
	for node_id in _nodes:
		_nodes[node_id].selected = node_id == id
	refresh()


# 詳細に表示している文章（名前・説明・価格）
func get_detail_text() -> String:
	return "%s\n%s\n%s" % [_name_label.text, _description_label.text, _cost_label.text]


func get_status_text() -> String:
	return _status_label.text


func refresh() -> void:
	for id in _nodes:
		_nodes[id].set_state(HubGoals.research_state(id))
	if _canvas:
		_canvas.queue_redraw()
	_refresh_detail()


# 研究できるもの（定義の順で最初）。無ければいま選んでいるもの、
# 何も選んでいなければまだ済んでいない最初のもの、すべて済んでいれば先頭
func _default_selection() -> String:
	var ids = Research.all_ids()
	for id in ids:
		if HubGoals.research_state(id) == Research.State.AVAILABLE:
			return id
	if _selected != "":
		return _selected
	for id in ids:
		if not HubGoals.is_researched(id):
			return id
	return ids[0]


func _refresh_detail() -> void:
	if _name_label == null or _selected == "":
		return
	var def = Research.get_def(_selected)
	var state = HubGoals.research_state(_selected)
	_name_label.text = def["name"]
	_description_label.text = def["description"]
	_cost_label.text = "価格: " + _cost_text(def["cost"])
	var color = AFFORDABLE_COLOR if HubGoals.can_afford(def["cost"]) else UNAFFORDABLE_COLOR
	if state == Research.State.DONE:
		color = DESCRIPTION_COLOR
	_cost_label.add_theme_color_override("font_color", color)
	_status_label.text = HubGoals.research_state_text(_selected)
	research_button.disabled = state != Research.State.AVAILABLE


# 価格は「手持ち/必要数」で示す
func _cost_text(cost: Dictionary) -> String:
	var parts: Array[String] = []
	for item_id in cost:
		var item = ItemDB.get_item(item_id)
		var item_name = item.display_name if item else item_id
		parts.append("%s %d/%d" % [item_name, HubGoals.get_stock(item_id), cost[item_id]])
	return "、".join(parts)


func _research_selected() -> void:
	if _selected != "":
		HubGoals.research(_selected)


# ---- 組み立て ----------------------------------------------------------------


func _build() -> void:
	var margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 18)
	add_child(margin)
	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 12)
	margin.add_child(layout)
	layout.add_child(_build_header())
	var body := HBoxContainer.new()
	body.add_theme_constant_override("separation", 16)
	layout.add_child(body)
	body.add_child(_build_tree())
	body.add_child(_build_detail())


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


func _build_tree() -> Control:
	var defs: Dictionary = Research.DEFS
	var cells := ResearchTreeLayout.cells(defs)
	var levels := ResearchTreeLayout.column_levels(defs)
	var branch_rows := ResearchTreeLayout.branch_rows(defs)
	var row_count := 0
	for rows in branch_rows.values():
		row_count += rows.size()

	_canvas = Control.new()
	_canvas.custom_minimum_size = Vector2(
		ROW_TITLE_WIDTH + levels.size() * COLUMN_WIDTH, HEADER_HEIGHT + row_count * ROW_HEIGHT
	)
	_canvas.draw.connect(_draw_tree.bind(branch_rows))

	for i in levels.size():
		var title := _make_label("Lv%d" % levels[i], 13, TITLE_COLOR)
		title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		title.position = Vector2(ROW_TITLE_WIDTH + i * COLUMN_WIDTH, 4)
		title.size = Vector2(COLUMN_WIDTH, HEADER_HEIGHT - 4)
		_canvas.add_child(title)
		_column_titles.append(title.text)
	for branch in Research.BRANCHES:
		if not branch_rows.has(branch):
			continue
		var rows: Array = branch_rows[branch]
		var title := _make_label(Research.branch_name(branch), 14, TITLE_COLOR)
		title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		title.position = Vector2(8, HEADER_HEIGHT + rows[0] * ROW_HEIGHT)
		title.size = Vector2(ROW_TITLE_WIDTH - 8, rows.size() * ROW_HEIGHT)
		_canvas.add_child(title)
		_row_titles.append(title.text)

	for id in Research.all_ids():
		var node := ResearchNode.new(id)
		var cell: Vector2i = cells[id]
		var cell_origin := Vector2(
			ROW_TITLE_WIDTH + cell.x * COLUMN_WIDTH, HEADER_HEIGHT + cell.y * ROW_HEIGHT
		)
		node.position = (
			cell_origin + (Vector2(COLUMN_WIDTH, ROW_HEIGHT) - ResearchNode.NODE_SIZE) * 0.5
		)
		node.pressed.connect(select.bind(id))
		_canvas.add_child(node)
		_nodes[id] = node
		for required in Research.get_def(id)["requires"]:
			_links.append([required, id])

	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(
		minf(_canvas.custom_minimum_size.x, TREE_VIEW_MAX.x),
		minf(_canvas.custom_minimum_size.y, TREE_VIEW_MAX.y)
	)
	scroll.add_child(_canvas)
	return scroll


# 系統ごとの帯（1つおきに薄く塗る）と、前提をつなぐ線
func _draw_tree(branch_rows: Dictionary) -> void:
	var stripe := false
	for branch in Research.BRANCHES:
		if not branch_rows.has(branch):
			continue
		var rows: Array = branch_rows[branch]
		if stripe:
			_canvas.draw_rect(
				Rect2(
					0,
					HEADER_HEIGHT + rows[0] * ROW_HEIGHT,
					_canvas.custom_minimum_size.x,
					rows.size() * ROW_HEIGHT
				),
				BAND_COLOR
			)
		stripe = not stripe
	for link in _links:
		var from := get_node_center(link[0]) + Vector2(ResearchNode.HEX_RADIUS, 0)
		var to := get_node_center(link[1]) - Vector2(ResearchNode.HEX_RADIUS, 0)
		_canvas.draw_line(from, to, get_link_color(link[0], link[1]), LINK_WIDTH, true)


func _build_detail() -> Control:
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(DETAIL_WIDTH, 0)
	card.add_theme_stylebox_override("panel", _make_box(DETAIL_COLOR, DETAIL_COLOR, 0, 8))
	var margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 14)
	card.add_child(margin)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	margin.add_child(box)
	_name_label = _make_label("", 18, NAME_COLOR)
	_name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_description_label = _make_label("", 13, DESCRIPTION_COLOR)
	_description_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_cost_label = _make_label("", 13, AFFORDABLE_COLOR)
	_cost_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	for label in [_name_label, _description_label, _cost_label]:
		box.add_child(label)
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(spacer)
	_status_label = _make_label("", 12, STATUS_COLOR)
	_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(_status_label)
	research_button = Button.new()
	research_button.text = BUTTON_TEXT
	research_button.custom_minimum_size = Vector2(0, 38)
	research_button.focus_mode = Control.FOCUS_NONE
	research_button.pressed.connect(_research_selected)
	box.add_child(research_button)
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
