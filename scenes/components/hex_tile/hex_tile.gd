@tool
class_name HexTile
extends Node2D

# HexTile - 個別の六角形タイル表示（床のマス、ピースのマス、設置のプレビュー）
# 画像は使わず、戦闘の盤面と同じ角のとがった六角形を描く

## 地面の種類（鉱床）を示す、中央のアイコンの大きさ（ピクセル）と濃さ
const ICON_SIZE := 44.0
const ICON_ALPHA := 0.55

var hex_coordinate: Vector2i
var is_highlighted: bool = false
var normal_color: Color = HexStyle.FLOOR_COLOR
# 橋の着地点（受け取りを置く場所）のヒント用の色
var highlight_color: Color = Color(0.55, 0.35, 0.25)
var _current_color: Color = HexStyle.FLOOR_COLOR  # 現在のHexの色 (ピースの色が優先される)
var _icon: Texture2D = null


# マスの中心から頂点までの距離。隣のマスとすき間なく並ぶ大きさ
static func visual_circumradius() -> float:
	return Layout.make_default().size.x


func setup_hex(hex: Vector2i):
	hex_coordinate = hex
	_current_color = normal_color  # 初期色を設定
	set_highlight(false)


# ハイライト状態を設定
func set_highlight(highlighted: bool):
	is_highlighted = highlighted
	queue_redraw()


# ピースの色を設定
func set_color(color: Color):
	_current_color = color
	queue_redraw()


# 色をリセット
func reset_color():
	_current_color = normal_color
	queue_redraw()


# 現在のピースの色を取得
func get_color() -> Color:
	return _current_color


# 地面の種類を示すアイコンを中央に薄く描く（鉱床のマスなら資源の品目）。null なら描かない
func set_icon(icon: Texture2D) -> void:
	_icon = icon
	queue_redraw()


func get_icon() -> Texture2D:
	return _icon


# 透明度を設定
func set_transparency(alpha: float):
	_current_color.a = clampf(alpha, 0.0, 1.0)  # アルファ値を0.0から1.0の範囲に制限
	queue_redraw()


# いま実際に塗っている色（ハイライト中はハイライトの色）
func get_fill_color() -> Color:
	return highlight_color if is_highlighted else _current_color


# 描いている六角形の輪郭（タイルの座標）
func get_outline() -> PackedVector2Array:
	return HexShape.outline(Vector2.ZERO, visual_circumradius(), true)


func _draw() -> void:
	HexShape.draw(self, Vector2.ZERO, visual_circumradius(), true, get_fill_color())
	if _icon:
		var size := Vector2(ICON_SIZE, ICON_SIZE)
		draw_texture_rect(_icon, Rect2(-size * 0.5, size), false, Color(1, 1, 1, ICON_ALPHA))
