class_name Battlefield
extends RefCounted
## 1戦ぶんのヘックス戦場。マスごとの地形を持ち、経路と移動可能範囲を求める。

enum Terrain { FLOOR, WALL }

var _terrain: Dictionary[Vector2i, Terrain] = {}
var _units: Dictionary[Vector2i, Unit] = {}


## 中心から radius マス以内がすべて床の六角形の戦場を作る。
static func hexagon(radius: int) -> Battlefield:
	var field := Battlefield.new()
	for hex in BattleHex.within(Vector2i.ZERO, radius):
		field.set_terrain(hex, Terrain.FLOOR)
	return field


func set_terrain(hex: Vector2i, terrain: Terrain) -> void:
	_terrain[hex] = terrain


func has_cell(hex: Vector2i) -> bool:
	return _terrain.has(hex)


func terrain_at(hex: Vector2i) -> Terrain:
	return _terrain[hex]


func cells() -> Array[Vector2i]:
	return _terrain.keys()


## 床で、かつユニットがいなければ通行できる。
func is_walkable(hex: Vector2i) -> bool:
	return _terrain.get(hex, Terrain.WALL) == Terrain.FLOOR and not _units.has(hex)


## ユニットを hex に置く。すでに戦場にいるユニットなら移動になる。
func place_unit(unit: Unit, hex: Vector2i) -> void:
	remove_unit(unit)
	unit.position = hex
	_units[hex] = unit


func remove_unit(unit: Unit) -> void:
	if _units.get(unit.position) == unit:
		_units.erase(unit.position)


func unit_at(hex: Vector2i) -> Unit:
	return _units.get(hex)


func units() -> Array[Unit]:
	return _units.values()


## from から to までの最短経路を両端を含めて返す。たどり着けなければ空。
func find_path(from: Vector2i, to: Vector2i) -> Array[Vector2i]:
	var came_from := _explore(from, -1, to)
	if not came_from.has(to):
		return []
	var path: Array[Vector2i] = [to]
	while path[0] != from:
		path.push_front(came_from[path[0]])
	return path


## from から max_steps 歩以内で行けるマスと、そこまでの歩数を返す。from 自身も歩数0で含む。
func reachable(from: Vector2i, max_steps: int) -> Dictionary[Vector2i, int]:
	var came_from := _explore(from, max_steps)
	var result: Dictionary[Vector2i, int] = {}
	for hex in came_from:
		var steps := 0
		var current: Vector2i = hex
		while current != from:
			current = came_from[current]
			steps += 1
		result[hex] = steps
	return result


## 幅優先で歩けるマスをたどり、各マスの直前のマスを返す。max_steps が負なら歩数は無制限。
func _explore(
	from: Vector2i, max_steps: int, goal: Variant = null
) -> Dictionary[Vector2i, Vector2i]:
	var came_from: Dictionary[Vector2i, Vector2i] = {from: from}
	var frontier: Array[Vector2i] = [from]
	var steps := 0
	while not frontier.is_empty() and steps != max_steps:
		var next_frontier: Array[Vector2i] = []
		for current in frontier:
			for neighbor in BattleHex.neighbors(current):
				if came_from.has(neighbor) or not is_walkable(neighbor):
					continue
				came_from[neighbor] = current
				if goal != null and neighbor == goal:
					return came_from
				next_frontier.append(neighbor)
		frontier = next_frontier
		steps += 1
	return came_from
