class_name PlayerView
extends Node2D
## プレイヤーキャラクターの表示。戦闘の主人公と同じ色の、陰影のない丸。

const OUTLINE_WIDTH := 3.0
## 縁取りまで含めた大きさを、当たり判定の体の大きさにそろえる
const RADIUS := PlayerCharacter.BODY_RADIUS - OUTLINE_WIDTH
# 案内の文字は、どちらの配色の地の上でも読めるよう白抜きの黒縁にする
const PROMPT_COLOR := Color.WHITE
const PROMPT_OUTLINE_COLOR := Color(0.1, 0.12, 0.16)
const PROMPT_SIZE := Vector2(160, 28)

var _prompt := Label.new()


func _init() -> void:
	name = "PlayerView"
	# 施設やベルトの上のアイテムより手前に描く
	z_index = 10
	_prompt.name = "Prompt"
	_prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_prompt.size = PROMPT_SIZE
	_prompt.position = Vector2(-PROMPT_SIZE.x / 2.0, -RADIUS - OUTLINE_WIDTH - PROMPT_SIZE.y - 4.0)
	_prompt.add_theme_font_size_override("font_size", 16)
	_prompt.add_theme_color_override("font_color", PROMPT_COLOR)
	_prompt.add_theme_color_override("font_outline_color", PROMPT_OUTLINE_COLOR)
	_prompt.add_theme_constant_override("outline_size", 6)
	_prompt.visible = false
	add_child(_prompt)


## キャラクターの上に出す操作の案内。空なら隠す
func set_prompt(text: String) -> void:
	_prompt.text = text
	_prompt.visible = text != ""


## その位置へ置く
func jump_to(target: Vector2) -> void:
	position = target


func _draw() -> void:
	draw_circle(Vector2.ZERO, RADIUS + OUTLINE_WIDTH, ColorTheme.color(&"player_outline"))
	draw_circle(Vector2.ZERO, RADIUS, UnitView.PLAYER_COLOR)
