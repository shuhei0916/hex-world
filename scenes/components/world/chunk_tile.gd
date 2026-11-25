class_name ChunkTile
extends Node2D

## ワールドマップの chunk 1つ分のタイル。ローカルの床のマス（HexTile）と同じ描き方の、
## 辺が上を向く六角形で描く。大きさは WorldMapView がローカル画面の chunk に合わせて決める。
## 今いる chunk とホバー中の chunk は、塗り（バイオームの色）を変えずに、タイルの内側に
## 一回り小さい六角形の輪を描いて示す。輪はタイルの内側に収めるので、隣のタイルに覆われない。

const TILE_SIZE := 80.0
const NORMAL_COLOR := Color("#2a4a2a")
# 今いる chunk の輪の太さ。ホバー中は細く、淡くする
const ACTIVE_RING_WIDTH := 6.0
const HOVER_RING_WIDTH := 3.0
const HOVER_RING_ALPHA := 0.55
# タイルの縁の線から輪までのすき間
const RING_GAP := 5.0

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


# 塗りの色。状態に関わらずバイオームの色のまま
func get_current_color() -> Color:
	return base_color


# いま実際に塗っている色
func get_fill_color() -> Color:
	return get_current_color()


# 描いている六角形の輪郭（タイルの座標）
func get_outline() -> PackedVector2Array:
	return HexShape.outline(Vector2.ZERO, _circumradius(), false)


# 状態を示す輪。{points: 線の中心を一周した頂点（最初の頂点に戻る）, color, width}。
# 今いる chunk でもホバー中でもなければ空
func get_ring() -> Dictionary:
	if not (is_active or is_hovered):
		return {}
	var width := ACTIVE_RING_WIDTH if is_active else HOVER_RING_WIDTH
	var color := ColorTheme.color(&"map_marker")
	if not is_active:
		color.a *= HOVER_RING_ALPHA
	# 線の太さも含めて、タイルの縁の線より内側に収める
	var center_inradius := _inradius - HexStyle.BORDER_WIDTH - RING_GAP - width * 0.5
	return {
		"points": HexShape.outline(Vector2.ZERO, _to_circumradius(center_inradius), false),
		"color": color,
		"width": width,
	}


func _draw() -> void:
	HexShape.draw(self, Vector2.ZERO, _circumradius(), false, get_fill_color())
	var ring := get_ring()
	if not ring.is_empty():
		_draw_ring(ring)


# 太い線を1本で描くと角が欠けるので、辺ごとの台形を並べて角まで埋める
func _draw_ring(ring: Dictionary) -> void:
	var center_inradius: float = ring["points"][0].length() * sqrt(3.0) * 0.5
	var half: float = ring["width"] * 0.5
	var outer := HexShape.corners(Vector2.ZERO, _to_circumradius(center_inradius + half), false)
	var inner := HexShape.corners(Vector2.ZERO, _to_circumradius(center_inradius - half), false)
	for i in 6:
		var j := (i + 1) % 6
		draw_colored_polygon(
			PackedVector2Array([outer[i], outer[j], inner[j], inner[i]]), ring["color"]
		)


func _circumradius() -> float:
	return _to_circumradius(_inradius)


static func _to_circumradius(inradius: float) -> float:
	return inradius * 2.0 / sqrt(3.0)
