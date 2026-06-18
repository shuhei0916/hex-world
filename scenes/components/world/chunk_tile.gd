class_name ChunkTile
extends Node2D

const TILE_SIZE := 80.0
const NORMAL_COLOR := Color("#2a4a2a")
const ACTIVE_COLOR := Color("#4a8c4a")
const BORDER_COLOR := Color("#aaaaaa")

var chunk_hex: Hex
var is_active: bool = false


func setup(hex: Hex) -> void:
	chunk_hex = hex


func set_active(active: bool) -> void:
	is_active = active
	queue_redraw()


func _draw() -> void:
	var color = ACTIVE_COLOR if is_active else NORMAL_COLOR
	var pts = _hex_corners()
	draw_colored_polygon(pts, color)
	draw_polyline(pts + PackedVector2Array([pts[0]]), BORDER_COLOR, 2.0)


func _hex_corners() -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in 6:
		var angle_rad = deg_to_rad(60.0 * i)  # flat-top（pointy-top hex グリッドの外形は flat-top）
		pts.append(Vector2(TILE_SIZE * cos(angle_rad), TILE_SIZE * sin(angle_rad)))
	return pts
