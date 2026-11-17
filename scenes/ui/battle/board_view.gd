class_name BoardView
extends Node2D
## 戦場のマスを描く。移動できるマスと、マウスを乗せた敵の予定を示す。

const REACHABLE_COLOR := Color(0.25, 0.45, 0.7)
const THREAT_COLOR := Color(0.9, 0.3, 0.25)
const PLAN_COLOR := Color(1.0, 0.7, 0.2)
const HOVER_COLOR := Color(1.0, 1.0, 1.0, 0.25)

var field: Battlefield
var hex_size := 40.0
var reachable: Dictionary[Vector2i, int] = {}
## マウスを乗せた敵に、次の敵ターンで攻撃されうるマス。
var threatened: Array[Vector2i] = []
## マウスを乗せた敵が次の手番で歩く予定の経路。
var plan_path: Array[Vector2i] = []
## その敵が移動のあと plan_target を攻撃する予定か。
var plan_attacks := false
var plan_target := Vector2i.ZERO
var hovered: Variant = null


func _draw() -> void:
	if field == null:
		return
	for hex in field.cells():
		var color := HexStyle.FLOOR_COLOR
		if field.terrain_at(hex) == Battlefield.Terrain.WALL:
			color = HexStyle.WALL_COLOR
		elif reachable.get(hex, 0) > 0:
			color = REACHABLE_COLOR
		HexShape.draw(self, BattleHex.to_pixel(hex, hex_size), hex_size, true, color)
	for hex in threatened:
		var center := BattleHex.to_pixel(hex, hex_size)
		draw_polyline(HexShape.outline(center, hex_size * 0.82, true), THREAT_COLOR, 2.0)
	_draw_plan()
	if hovered != null and field.has_cell(hovered):
		draw_colored_polygon(_corners(hovered, hex_size), HOVER_COLOR)


func _draw_plan() -> void:
	if plan_path.is_empty():
		return
	var points := PackedVector2Array()
	for hex in plan_path:
		points.append(BattleHex.to_pixel(hex, hex_size))
	if points.size() > 1:
		draw_polyline(points, PLAN_COLOR, 5.0)
		draw_circle(points[points.size() - 1], 9.0, PLAN_COLOR)
	if plan_attacks:
		draw_colored_polygon(_corners(plan_target, hex_size), Color(THREAT_COLOR, 0.45))
		var target_point := BattleHex.to_pixel(plan_target, hex_size)
		draw_line(points[points.size() - 1], target_point, THREAT_COLOR, 5.0)


func _corners(hex: Vector2i, radius: float) -> PackedVector2Array:
	return HexShape.corners(BattleHex.to_pixel(hex, hex_size), radius, true)
