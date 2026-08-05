class_name ChunkTile
extends Node2D

const TILE_SIZE := 80.0
const NORMAL_COLOR := Color("#2a4a2a")
const ACTIVE_COLOR := Color("#4a8c4a")
const HOVER_COLOR := Color("#3a6a8c")
const BORDER_COLOR := Color("#aaaaaa")

var chunk_hex: Hex
var is_active: bool = false
var is_hovered: bool = false


func setup(hex: Hex) -> void:
	chunk_hex = hex


func set_active(active: bool) -> void:
	is_active = active
	queue_redraw()


func set_hovered(hovered: bool) -> void:
	is_hovered = hovered
	queue_redraw()


func get_current_color() -> Color:
	if is_active:
		return ACTIVE_COLOR
	if is_hovered:
		return HOVER_COLOR
	return NORMAL_COLOR


func _draw() -> void:
	var pts = _hex_corners()
	draw_colored_polygon(pts, get_current_color())
	draw_polyline(pts + PackedVector2Array([pts[0]]), BORDER_COLOR, 2.0)


func _hex_corners() -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in 6:
		var angle_rad = deg_to_rad(60.0 * i)  # flat-top（pointy-top hex グリッドの外形は flat-top）
		pts.append(Vector2(TILE_SIZE * cos(angle_rad), TILE_SIZE * sin(angle_rad)))
	return pts
