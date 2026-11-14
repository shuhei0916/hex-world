class_name ItemPicker
extends PanelContainer

## 搬出チェストが取り出すアイテムを選ぶパネル。
## アイテムの一覧は ItemDB から作る。選ぶと対象のチェストに設定して閉じる。

const COLUMNS := 3
const TITLE_TEXT := "取り出すアイテム"
const NONE_TEXT := "取り出さない"

var _buttons: Dictionary = {}  # item_id（"" は「取り出さない」）→ Button
# 設定先の ChestOutput（撤去されて無効になることがあるので型は付けない）
var _target = null


func _ready() -> void:
	visible = false
	_build()


# piece が搬出チェストなら、そのチェスト用にパネルを開く
func open(piece: Piece) -> void:
	var output = piece.get_node_or_null("ChestOutput") if piece else null
	if output == null:
		return
	_target = output
	visible = true


func close() -> void:
	_target = null
	visible = false


func get_button(item_id: String) -> Button:
	return _buttons.get(item_id)


func _pick(item_id: String) -> void:
	if is_instance_valid(_target):
		_target.select_item(item_id)
	close()


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
	title.add_theme_font_size_override("font_size", 20)
	layout.add_child(title)
	var grid := GridContainer.new()
	grid.columns = COLUMNS
	layout.add_child(grid)
	for item_id in ItemDB.all_ids():
		var item = ItemDB.get_item(item_id)
		grid.add_child(_build_button(item_id, item.display_name, item.icon))
	layout.add_child(_build_button("", NONE_TEXT, null))


func _build_button(item_id: String, text: String, icon: Texture2D) -> Button:
	var button := Button.new()
	button.text = text
	button.icon = icon
	button.expand_icon = true
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.custom_minimum_size = Vector2(170, 36)
	button.focus_mode = Control.FOCUS_NONE
	button.pressed.connect(func(): _pick(item_id))
	_buttons[item_id] = button
	return button
