class_name ChunkTile
extends Node2D

## ワールドマップの chunk 1つ分のタイル。ローカルの床のマス（HexTile）と同じ描き方の、
## 辺が上を向く六角形で描く。大きさは WorldMapView がローカル画面の chunk に合わせて決める。

const TILE_SIZE := 80.0
const NORMAL_COLOR := Color("#2a4a2a")
const ACTIVE_BORDER_COLOR := Color("#ffffff")
const ACTIVE_BORDER_WIDTH := 4.0
# 基本色（バイオーム色）を保ったまま状態が分かるよう、明るさで表す
const HOVER_LIGHTEN := 0.2
const ACTIVE_LIGHTEN := 0.4

var chunk_hex: Vector2i
var base_color: Color = NORMAL_COLOR
var is_active: bool = false
var is_hovered: bool = false

var _inradius := TILE_SIZE * sqrt(3.0) * 0.5


# 中心から辺までの距離を指定して、その大きさで描く
func set_inradius(inradius: float) -> void:
	_inradius = inradius
	queue_redraw()


func get_inradius() -> float:
	return _inradius


func setup(hex: Vector2i, color: Color = NORMAL_COLOR) -> void:
	chunk_hex = hex
	base_color = color
	queue_redraw()


func set_active(active: bool) -> void:
	is_active = active
	queue_redraw()


func set_hovered(hovered: bool) -> void:
	is_hovered = hovered
	queue_redraw()


func get_current_color() -> Color:
	if is_active:
		return base_color.lightened(ACTIVE_LIGHTEN)
	if is_hovered:
		return base_color.lightened(HOVER_LIGHTEN)
	return base_color


# いま実際に塗っている色
func get_fill_color() -> Color:
	return get_current_color()


# 描いている六角形の輪郭（タイルの座標）
func get_outline() -> PackedVector2Array:
	return HexShape.outline(Vector2.ZERO, _circumradius(), false)


# 今いる chunk だけ、白く縁取る
func _draw() -> void:
	HexShape.draw(self, Vector2.ZERO, _circumradius(), false, get_fill_color())
	if is_active:
		draw_polyline(get_outline(), ACTIVE_BORDER_COLOR, ACTIVE_BORDER_WIDTH, true)


func _circumradius() -> float:
	return _inradius * 2.0 / sqrt(3.0)
