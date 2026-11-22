class_name ReachArea
extends Node2D
## キャラクターから建築できる範囲のマスを、うっすら明るく示す。

const FILL := Color(1.0, 1.0, 1.0, 0.08)

var layout: Layout = Layout.make_default()
var hexes: Array[Vector2i] = []


func _init() -> void:
	name = "ReachArea"


func show_hexes(new_hexes: Array[Vector2i]) -> void:
	hexes = new_hexes
	queue_redraw()


func _draw() -> void:
	var radius := HexTile.visual_circumradius()
	for hex in hexes:
		draw_colored_polygon(HexShape.corners(Layout.hex_to_pixel(layout, hex), radius, true), FILL)
