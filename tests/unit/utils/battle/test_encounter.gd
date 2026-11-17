extends GutTest

## 戦場に主人公と敵を置いて1戦を作る。戦場の大きさと壁は呼び出し側が決める。

const RADIUS := 5

var player: Unit


func before_each():
	player = Unit.new(Unit.Team.PLAYER, 30, 3)


func _generate(stage: int, rng_seed: int, walls: Array[Vector2i] = []) -> Battle:
	var rng := RandomNumberGenerator.new()
	rng.seed = rng_seed
	return Encounter.generate(stage, player, rng, RADIUS, walls)


func _walls(battle: Battle) -> Array:
	return battle.field.cells().filter(
		func(hex: Vector2i) -> bool: return battle.field.terrain_at(hex) == Battlefield.Terrain.WALL
	)


func _enemy_positions(battle: Battle) -> Array:
	return battle.enemies().map(func(unit: Unit) -> Vector2i: return unit.position)


func test_渡した主人公が戦場に置かれる():
	var battle := _generate(1, 1)

	assert_eq(battle.player, player)
	assert_eq(battle.field.unit_at(player.position), player)


func test_戦場は渡した半径の六角形になる():
	var battle := _generate(1, 1)

	assert_eq(battle.field.cells().size(), BattleHex.within(Vector2i.ZERO, RADIUS).size())


func test_主人公は戦場の端の近くから始まる():
	_generate(1, 1)

	assert_eq(player.position, Encounter.player_start(RADIUS))
	assert_eq(BattleHex.distance(player.position, Vector2i.ZERO), RADIUS - 1)


func test_最初の戦闘は敵が2体():
	assert_eq(_generate(1, 1).enemies().size(), 2)


func test_進むほど敵が増える():
	assert_gt(_generate(4, 1).enemies().size(), _generate(1, 1).enemies().size())


func test_最後の戦闘にはHPの高いボスがいる():
	var hps := _generate(Encounter.STAGE_COUNT, 1).enemies().map(
		func(unit: Unit) -> int: return unit.max_hp
	)

	assert_gte(hps.max(), 20)


func test_敵は主人公から離れた場所に置かれる():
	for rng_seed in range(1, 11):
		for enemy in _generate(3, rng_seed).enemies():
			assert_gte(BattleHex.distance(enemy.position, player.position), 4)


func test_壁を渡さなければ壁は無い():
	assert_eq(_walls(_generate(1, 1)).size(), 0)


func test_渡したマスが壁になる():
	var walls: Array[Vector2i] = [Vector2i(0, 0), Vector2i(1, 0)]

	var battle := _generate(1, 1, walls)

	assert_eq(_walls(battle).size(), 2)
	assert_eq(battle.field.terrain_at(Vector2i(0, 0)), Battlefield.Terrain.WALL)
	assert_eq(battle.field.terrain_at(Vector2i(1, 0)), Battlefield.Terrain.WALL)


func test_戦場の外にある壁は無視する():
	var walls: Array[Vector2i] = [Vector2i(RADIUS + 3, 0)]

	var battle := _generate(1, 1, walls)

	assert_false(battle.field.has_cell(Vector2i(RADIUS + 3, 0)))


func test_敵は壁の上には置かれない():
	var walls: Array[Vector2i] = []
	for hex in BattleHex.within(Vector2i(2, 0), 2):
		walls.append(hex)

	for rng_seed in range(1, 11):
		for position in _enemy_positions(_generate(4, rng_seed, walls)):
			assert_does_not_have(walls, position)


func test_開始位置が壁なら主人公はいちばん近い歩けるマスから始まる():
	var start := Encounter.player_start(RADIUS)
	var walls: Array[Vector2i] = [start]

	_generate(1, 1, walls)

	assert_eq(BattleHex.distance(player.position, start), 1)


func test_同じシードなら同じ配置になる():
	var first := _enemy_positions(_generate(2, 5))

	assert_eq(_enemy_positions(_generate(2, 5)), first)


func test_シードが違えば配置が変わる():
	assert_ne(_enemy_positions(_generate(2, 5)), _enemy_positions(_generate(2, 6)))
