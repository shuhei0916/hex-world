class_name ChunkTile
extends Node2D

const TILE_SIZE := 80.0
const NORMAL_COLOR := Color("#2a4a2a")
const BORDER_COLOR := Color("#aaaaaa")
const ACTIVE_BORDER_COLOR := Color("#ffffff")
# 基本色（バイオーム色）を保ったまま状態が分かるよう、明るさで表す
const HOVER_LIGHTEN := 0.2
const ACTIVE_LIGHTEN := 0.4

var chunk_hex: Hex
var base_color: Color = NORMAL_COLOR
var is_active: bool = false
var is_hovered: bool = false


func setup(hex: Hex, color: Color = NORMAL_COLOR) -> void:
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


func _draw() -> void:
	var pts = _hex_corners()
	draw_colored_polygon(pts, get_current_color())
	var border = ACTIVE_BORDER_COLOR if is_active else BORDER_COLOR
	draw_polyline(pts + PackedVector2Array([pts[0]]), border, 4.0 if is_active else 2.0)


func _hex_corners() -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in 6:
		var angle_rad = deg_to_rad(60.0 * i)  # flat-top（pointy-top hex グリッドの外形は flat-top）
		pts.append(Vector2(TILE_SIZE * cos(angle_rad), TILE_SIZE * sin(angle_rad)))
	return pts
