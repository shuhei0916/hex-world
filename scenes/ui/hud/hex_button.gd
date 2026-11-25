class_name HexButton
extends Button

# ツールバー用の、とがった頂点が上下に来る六角形のボタン。
# 押せる範囲も六角形にそろえる（隣のボタンとの間の四角い角では反応しない）。
# Button の icon を使うと四角いボタン用の描画が上に重なるので、アイコンは hex_icon に持たせて自分で描く。

# 色は配色（button_*）から描くたびに引く
const OUTLINE_WIDTH := 1.5
const ICON_RATIO := 1.05
const HINT_FONT_SIZE := 10

@export var hex_icon: Texture2D:
	set(value):
		hex_icon = value
		queue_redraw()

# ボタンの下のほうに小さく出す文字（ショートカットキーの数字など）
@export var hint: String = "":
	set(value):
		hint = value
		queue_redraw()


func _init() -> void:
	flat = true
	focus_mode = Control.FOCUS_NONE


func _has_point(point: Vector2) -> bool:
	return Geometry2D.is_point_in_polygon(point, _hex_points())


func _draw() -> void:
	var points := _hex_points()
	var mode := get_draw_mode()
	draw_colored_polygon(points, _fill_color(mode))
	var outline := points.duplicate()
	outline.append(points[0])
	var pressed := mode == DRAW_PRESSED or mode == DRAW_HOVER_PRESSED
	draw_polyline(
		outline,
		ColorTheme.color(&"button_outline_pressed" if pressed else &"button_outline"),
		OUTLINE_WIDTH,
		true
	)
	if hex_icon:
		var side := _radius() * ICON_RATIO
		var rect := Rect2(size * 0.5 - Vector2(side, side) * 0.5, Vector2(side, side))
		draw_texture_rect(hex_icon, rect, false, get_icon_color())
	if hint != "":
		var font := get_theme_default_font()
		var baseline := Vector2(0, size.y * 0.5 + _radius() * 0.82)
		draw_string(
			font,
			baseline,
			hint,
			HORIZONTAL_ALIGNMENT_CENTER,
			size.x,
			HINT_FONT_SIZE,
			ColorTheme.color(&"button_hint")
		)


# アイコンは白い線画なので、掛ける色で配色に合わせる（ライトではインクの色）
func get_icon_color() -> Color:
	return ColorTheme.color(&"button_icon")


func _fill_color(mode: DrawMode) -> Color:
	match mode:
		DRAW_PRESSED, DRAW_HOVER_PRESSED:
			return ColorTheme.color(&"button_pressed")
		DRAW_HOVER:
			return ColorTheme.color(&"button_hover")
		DRAW_DISABLED:
			return ColorTheme.color(&"button_disabled")
	return ColorTheme.color(&"button_fill")


# 外接円の半径。ボタンの四角に収まる最大の六角形にする
func _radius() -> float:
	return minf(size.x / sqrt(3.0), size.y * 0.5)


func _hex_points() -> PackedVector2Array:
	var center := size * 0.5
	var r := _radius()
	var points := PackedVector2Array()
	for i in 6:
		var angle := deg_to_rad(-90.0 + 60.0 * i)
		points.append(center + Vector2(cos(angle), sin(angle)) * r)
	return points
