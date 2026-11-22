class_name UnitView
extends Node2D
## ユニット1体の仮表示。陣営の色の丸と残りHPを描く。

const PLAYER_COLOR := Color(0.35, 0.75, 0.95)
const ENEMY_COLOR := Color(0.9, 0.4, 0.35)
const RADIUS := 22.0

var unit: Unit

var _hp_label := Label.new()
var _block_label := Label.new()


func _init() -> void:
	_hp_label.name = "HpLabel"
	_hp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hp_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_hp_label.size = Vector2(RADIUS, RADIUS) * 2.0
	_hp_label.position = -Vector2(RADIUS, RADIUS)
	_hp_label.add_theme_color_override("font_color", Color.BLACK)
	_hp_label.add_theme_font_size_override("font_size", 20)
	add_child(_hp_label)
	_block_label.name = "BlockLabel"
	_block_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_block_label.size = Vector2(RADIUS * 2.0, 20.0)
	_block_label.position = Vector2(-RADIUS, RADIUS - 6.0)
	_block_label.add_theme_color_override("font_color", Color(0.6, 0.85, 1.0))
	_block_label.add_theme_color_override("font_outline_color", Color.BLACK)
	_block_label.add_theme_constant_override("outline_size", 6)
	_block_label.add_theme_font_size_override("font_size", 16)
	add_child(_block_label)


## ユニットの現在の位置とHPを表示に反映する。
func refresh(hex_size: float) -> void:
	position = Hex.to_pixel(unit.position, hex_size)
	modulate = Color.WHITE
	show_hp(unit.hp)
	show_block(unit.block)
	queue_redraw()


func show_hp(hp: int) -> void:
	_hp_label.text = str(hp)


## ブロックの値を出す。0 なら隠す。
func show_block(block: int) -> void:
	_block_label.text = str(block)
	_block_label.visible = block > 0


func _draw() -> void:
	draw_circle(
		Vector2.ZERO, RADIUS, PLAYER_COLOR if unit.team == Unit.Team.PLAYER else ENEMY_COLOR
	)
