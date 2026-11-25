class_name TransferCard
extends Node2D

## ワールドマップで、橋による chunk から chunk への輸送を表す小さなカード。
## 運ぶ向きの矢印と、その下に「品目のアイコン＋毎分の個数」を多い順に並べる。
## まだ何も運んでいなければ矢印だけを描く。大きさはワールドマップの座標（タイルの半径 ≒ 70）。

const ARROW_SIZE := 20.0
const CORNER_RADIUS := 6.0
const PADDING := 5.0
const ROW_HEIGHT := 20.0
const ICON_SIZE := 18.0
const FONT_SIZE := 15
const WIDTH := 80.0

# 運ぶ向き（ワールドマップの座標の単位ベクトル）
var direction := Vector2.RIGHT

var _rows: Array = []  # [品目, "60/分"]


# items: {品目: 個/分}
func setup(dir: Vector2, items: Dictionary) -> void:
	direction = dir.normalized()
	var names = items.keys()
	names.sort_custom(func(a, b): return items[a] > items[b])
	_rows = names.map(func(n): return [n, "%d/分" % roundi(items[n])])
	queue_redraw()


func get_rows() -> Array:
	return _rows


func get_size() -> Vector2:
	if _rows.is_empty():
		return Vector2(ARROW_SIZE, ARROW_SIZE) * 2.0
	return Vector2(WIDTH, PADDING * 2.0 + ARROW_SIZE * 1.5 + ROW_HEIGHT * _rows.size())


func _draw() -> void:
	if _rows.is_empty():
		_draw_arrow(Vector2.ZERO, ARROW_SIZE * 1.3)
		return
	var size = get_size()
	var top_left = -size * 0.5
	_draw_background(Rect2(top_left, size))
	var arrow_center = Vector2(0.0, top_left.y + PADDING + ARROW_SIZE * 0.75)
	_draw_arrow(arrow_center, ARROW_SIZE)
	var font = ThemeDB.fallback_font
	var row_top = top_left.y + PADDING + ARROW_SIZE * 1.5
	for row in _rows:
		var icon_pos = Vector2(top_left.x + PADDING, row_top + (ROW_HEIGHT - ICON_SIZE) * 0.5)
		var item = ItemDB.get_item(row[0])
		if item and item.icon:
			draw_texture_rect(item.icon, Rect2(icon_pos, Vector2(ICON_SIZE, ICON_SIZE)), false)
		var baseline = row_top + ROW_HEIGHT * 0.5 + FONT_SIZE * 0.35
		var text_left = icon_pos.x + ICON_SIZE + 4.0
		draw_string(
			font,
			Vector2(text_left, baseline),
			row[1],
			HORIZONTAL_ALIGNMENT_LEFT,
			-1,
			FONT_SIZE,
			ColorTheme.color(&"card_text")
		)
		row_top += ROW_HEIGHT


func _draw_arrow(center: Vector2, size: float) -> void:
	draw_colored_polygon(arrow_shape(center, direction, size), ColorTheme.color(&"card_arrow"))


# 運ぶ向きを指す軸付きの矢印（→。先端が最初の点）。三角形だけだと、斜めのときにどの角が先端か
# 見分けにくい。center を矢印の長さの真ん中にして、どの向きでも同じ場所に収まるようにする
static func arrow_shape(center: Vector2, dir: Vector2, size: float) -> PackedVector2Array:
	var side = dir.orthogonal()
	var tip = center + dir * size * 0.7
	var neck = tip - dir * size * 0.55  # 矢じりの付け根
	var tail = center - dir * size * 0.7
	var head = side * size * 0.45
	var shaft = side * size * 0.14
	return PackedVector2Array(
		[tip, neck + head, neck + shaft, tail + shaft, tail - shaft, neck - shaft, neck - head]
	)


# 角を丸めた背景
func _draw_background(rect: Rect2) -> void:
	var box := StyleBoxFlat.new()
	box.bg_color = ColorTheme.color(&"card_background")
	box.set_corner_radius_all(int(CORNER_RADIUS))
	box.anti_aliasing = true
	draw_style_box(box, rect)
