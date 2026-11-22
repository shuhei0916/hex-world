class_name ResearchNode
extends Button

## 研究ツリーの1つの研究。角のとがった平らな六角形を状態の色で塗り、中に価格の品目のアイコン、
## 下に研究の名前を出す。選んでいるあいだは六角形を白い線で縁取る。

const HEX_RADIUS := 26.0
const NODE_SIZE := Vector2(92, 86)
const HEX_CENTER := Vector2(NODE_SIZE.x * 0.5, HEX_RADIUS + 2.0)
const ICON_SIZE := 28.0
const NAME_FONT_SIZE := 12
# 名前はノードより少し広い幅で折り返す（「コンベア高速化 II」が1行に収まるように）
const NAME_WIDTH := 116.0
const SELECTED_OUTLINE := Color(1, 1, 1)
const SELECTED_WIDTH := 3.0

const _STATE_COLORS = {
	Research.State.DONE: Color("#4fa3d9"),
	Research.State.AVAILABLE: Color("#e0b44a"),
	Research.State.UNAFFORDABLE: Color("#5a6478"),
	Research.State.LOCKED_CONDITION: Color("#2c323d"),
	Research.State.LOCKED_PREREQUISITE: Color("#2c323d"),
	Research.State.LOCKED_LEVEL: Color("#2c323d"),
}
const _NAME_COLOR := Color(0.9, 0.92, 0.96)
const _LOCKED_NAME_COLOR := Color(0.55, 0.58, 0.64)

var research_id: String
var selected := false:
	set(value):
		selected = value
		queue_redraw()

var _state: Research.State = Research.State.LOCKED_LEVEL
var _icon: Texture2D
var _name_label: Label


func _init(id: String = "") -> void:
	research_id = id
	custom_minimum_size = NODE_SIZE
	size = NODE_SIZE
	flat = true
	focus_mode = Control.FOCUS_NONE
	tooltip_text = Research.get_def(id).get("name", "")
	var cost: Dictionary = Research.get_def(id).get("cost", {})
	if not cost.is_empty():
		var item = ItemDB.get_item(cost.keys()[0])
		_icon = item.icon if item else null
	_name_label = Label.new()
	_name_label.text = Research.get_def(id).get("name", "")
	_name_label.add_theme_font_size_override("font_size", NAME_FONT_SIZE)
	_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_name_label.position = Vector2(
		(NODE_SIZE.x - NAME_WIDTH) * 0.5, HEX_CENTER.y + HEX_RADIUS + 2.0
	)
	_name_label.size = Vector2(NAME_WIDTH, NODE_SIZE.y - _name_label.position.y)
	add_child(_name_label)


func set_state(state: Research.State) -> void:
	_state = state
	var locked := not state in [Research.State.DONE, Research.State.AVAILABLE]
	_name_label.add_theme_color_override(
		"font_color", _LOCKED_NAME_COLOR if locked else _NAME_COLOR
	)
	queue_redraw()


func get_state() -> Research.State:
	return _state


func get_fill_color() -> Color:
	return _STATE_COLORS[_state]


static func hex_points(center: Vector2, radius: float) -> PackedVector2Array:
	var points := PackedVector2Array()
	for i in 6:
		points.append(center + Vector2.from_angle(deg_to_rad(60.0 * i - 90.0)) * radius)
	return points


func _draw() -> void:
	var points := hex_points(HEX_CENTER, HEX_RADIUS)
	draw_colored_polygon(points, get_fill_color())
	if selected:
		var ring := hex_points(HEX_CENTER, HEX_RADIUS + SELECTED_WIDTH)
		ring.append(ring[0])
		draw_polyline(ring, SELECTED_OUTLINE, SELECTED_WIDTH, true)
	if _icon:
		var alpha := 1.0 if _state in [Research.State.DONE, Research.State.AVAILABLE] else 0.45
		var icon_size := Vector2(ICON_SIZE, ICON_SIZE)
		draw_texture_rect(
			_icon, Rect2(HEX_CENTER - icon_size * 0.5, icon_size), false, Color(1, 1, 1, alpha)
		)
