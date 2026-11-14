class_name ChunkTile
extends Node2D

## ワールドマップの chunk 1つ分のタイル。ローカルの床のマス（HexTile）と同じ形の
## flat-top 版の画像で描く。大きさは WorldMapView がローカル画面の chunk に合わせて決める。

const TILE_SIZE := 80.0
const NORMAL_COLOR := Color("#2a4a2a")
const ACTIVE_BORDER_COLOR := Color("#ffffff")
const ACTIVE_BORDER_WIDTH := 4.0
# 基本色（バイオーム色）を保ったまま状態が分かるよう、明るさで表す
const HOVER_LIGHTEN := 0.2
const ACTIVE_LIGHTEN := 0.4
# 角の丸みの縁取りを何本の線分で描くか（角1つあたり）
const CORNER_SEGMENTS := 6

var chunk_hex: Hex
var base_color: Color = NORMAL_COLOR
var is_active: bool = false
var is_hovered: bool = false

var _sprite := Sprite2D.new()


func _init() -> void:
	_sprite.name = "Sprite2D"
	_sprite.texture = HexTile.FLAT_TEXTURE
	add_child(_sprite)
	set_inradius(TILE_SIZE * sqrt(3.0) * 0.5)


# 中心から辺までの距離を指定して、その大きさで描く
func set_inradius(inradius: float) -> void:
	_sprite.scale = Vector2.ONE * inradius / _image_inradius()
	queue_redraw()


func get_inradius() -> float:
	return _sprite.scale.x * _image_inradius()


static func _image_inradius() -> float:
	return HexTile.TEXTURE_CIRCUMRADIUS * sqrt(3.0) * 0.5


func get_sprite() -> Sprite2D:
	return _sprite


func setup(hex: Hex, color: Color = NORMAL_COLOR) -> void:
	chunk_hex = hex
	base_color = color
	_refresh()


func set_active(active: bool) -> void:
	is_active = active
	_refresh()


func set_hovered(hovered: bool) -> void:
	is_hovered = hovered
	_refresh()


func get_current_color() -> Color:
	if is_active:
		return base_color.lightened(ACTIVE_LIGHTEN)
	if is_hovered:
		return base_color.lightened(HOVER_LIGHTEN)
	return base_color


func _refresh() -> void:
	_sprite.modulate = get_current_color()
	queue_redraw()


# 今いる chunk だけ、画像の形に沿って白く縁取る
func _draw() -> void:
	if not is_active:
		return
	var outline = _rounded_outline()
	outline.append(outline[0])
	draw_polyline(outline, ACTIVE_BORDER_COLOR, ACTIVE_BORDER_WIDTH, true)


# 画像の中の角の丸い六角形の輪郭（flat-top、タイルの座標）
func _rounded_outline() -> PackedVector2Array:
	var pixel_scale = _sprite.scale.x
	var corner = HexTile.TEXTURE_CORNER_RADIUS * pixel_scale
	var inradius = HexTile.TEXTURE_CIRCUMRADIUS * sqrt(3.0) * 0.5 * pixel_scale
	# 丸みの円の中心までの距離（平らな辺の位置を変えずに角を丸めたときの値）
	var corner_center = (inradius - corner) * 2.0 / sqrt(3.0)
	var pts := PackedVector2Array()
	for i in 6:
		var angle = deg_to_rad(60.0 * i)
		var center = Vector2.RIGHT.rotated(angle) * corner_center
		for s in CORNER_SEGMENTS + 1:
			var t = angle + deg_to_rad(-30.0 + 60.0 * s / CORNER_SEGMENTS)
			pts.append(center + Vector2.RIGHT.rotated(t) * corner)
	return pts
