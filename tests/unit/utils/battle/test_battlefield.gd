extends GutTest

var field: Battlefield


func before_each():
	field = Battlefield.hexagon(3)


func test_六角形の戦場は半径内のマスを持つ():
	assert_true(field.has_cell(Vector2i(0, 0)))
	assert_true(field.has_cell(Vector2i(3, -3)))
	assert_false(field.has_cell(Vector2i(4, 0)))
	assert_eq(field.cells().size(), 37)


func test_床は通行できる():
	assert_true(field.is_walkable(Vector2i(1, 1)))


func test_壁は通行できない():
	field.set_terrain(Vector2i(1, 1), Battlefield.Terrain.WALL)

	assert_false(field.is_walkable(Vector2i(1, 1)))


func test_戦場の外は通行できない():
	assert_false(field.is_walkable(Vector2i(9, 9)))


func test_同じマスへの経路はそのマスのみ():
	assert_eq(field.find_path(Vector2i(0, 0), Vector2i(0, 0)), [Vector2i(0, 0)])


func test_障害物がなければ最短の経路を返す():
	var path := field.find_path(Vector2i(-2, 0), Vector2i(2, 0))

	assert_eq(path.size(), 5)
	assert_eq(path.front(), Vector2i(-2, 0))
	assert_eq(path.back(), Vector2i(2, 0))


func test_壁を迂回した経路を返す():
	for wall in [Vector2i(0, 0), Vector2i(0, -1), Vector2i(0, 1)]:
		field.set_terrain(wall, Battlefield.Terrain.WALL)

	var path := field.find_path(Vector2i(-1, 0), Vector2i(1, 0))

	assert_eq(path.front(), Vector2i(-1, 0))
	assert_eq(path.back(), Vector2i(1, 0))
	assert_gt(path.size(), 3)
	for i in range(1, path.size()):
		assert_eq(Hex.distance(path[i - 1], path[i]), 1)
		assert_true(field.is_walkable(path[i]))


func test_到達できないマスへの経路は空():
	for wall in Hex.neighbors(Vector2i(2, 0)):
		field.set_terrain(wall, Battlefield.Terrain.WALL)

	assert_eq(field.find_path(Vector2i(0, 0), Vector2i(2, 0)), [])


func test_壁への経路は空():
	field.set_terrain(Vector2i(1, 0), Battlefield.Terrain.WALL)

	assert_eq(field.find_path(Vector2i(0, 0), Vector2i(1, 0)), [])


func test_移動可能範囲は歩数以内のマスと歩数を返す():
	var reachable := field.reachable(Vector2i(0, 0), 2)

	assert_eq(reachable.size(), 19)
	assert_eq(reachable[Vector2i(0, 0)], 0)
	assert_eq(reachable[Vector2i(1, 0)], 1)
	assert_eq(reachable[Vector2i(2, -1)], 2)
	assert_does_not_have(reachable, Vector2i(3, 0))


func test_移動可能範囲は壁を含まず迂回の歩数で数える():
	for wall in [Vector2i(1, 0), Vector2i(1, -1)]:
		field.set_terrain(wall, Battlefield.Terrain.WALL)

	var reachable := field.reachable(Vector2i(0, 0), 4)

	assert_does_not_have(reachable, Vector2i(1, 0))
	assert_eq(reachable[Vector2i(2, -1)], 4)


func test_配置したユニットをマスから取得できる():
	var unit := Unit.new(Unit.Team.PLAYER, 10, 3)

	field.place_unit(unit, Vector2i(1, 0))

	assert_eq(field.unit_at(Vector2i(1, 0)), unit)
	assert_eq(unit.position, Vector2i(1, 0))
	assert_null(field.unit_at(Vector2i(0, 0)))


func test_ユニットを動かすと元のマスは空く():
	var unit := Unit.new(Unit.Team.PLAYER, 10, 3)
	field.place_unit(unit, Vector2i(1, 0))

	field.place_unit(unit, Vector2i(2, 0))

	assert_null(field.unit_at(Vector2i(1, 0)))
	assert_eq(field.unit_at(Vector2i(2, 0)), unit)


func test_取り除いたユニットのマスは空く():
	var unit := Unit.new(Unit.Team.ENEMY, 10, 3)
	field.place_unit(unit, Vector2i(1, 0))

	field.remove_unit(unit)

	assert_null(field.unit_at(Vector2i(1, 0)))
	assert_eq(field.units(), [])


func test_ユニットのいるマスは通行できない():
	field.place_unit(Unit.new(Unit.Team.ENEMY, 10, 3), Vector2i(1, 0))

	assert_false(field.is_walkable(Vector2i(1, 0)))


func test_経路はユニットのいるマスを避ける():
	for blocked in [Vector2i(0, 0), Vector2i(0, -1), Vector2i(0, 1)]:
		field.place_unit(Unit.new(Unit.Team.ENEMY, 10, 3), blocked)

	var path := field.find_path(Vector2i(-1, 0), Vector2i(1, 0))

	assert_gt(path.size(), 3)
