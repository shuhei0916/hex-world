extends GutTest

var player: Unit


func before_each():
	player = Unit.new(Unit.Team.PLAYER, 30, 3)


func _generate(stage: int, rng_seed: int) -> Battle:
	var rng := RandomNumberGenerator.new()
	rng.seed = rng_seed
	return Encounter.generate(stage, player, rng)


func _walls(battle: Battle) -> Array:
	return battle.field.cells().filter(
		func(hex: Vector2i) -> bool: return battle.field.terrain_at(hex) == Battlefield.Terrain.WALL
	)


func test_渡した主人公が戦場に置かれる():
	var battle := _generate(1, 1)

	assert_eq(battle.player, player)
	assert_eq(battle.field.unit_at(player.position), player)


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


func test_壁が置かれる():
	assert_gt(_walls(_generate(1, 1)).size(), 0)


func test_壁で分断されずどの床にも主人公から歩いて行ける():
	for rng_seed in range(1, 21):
		var battle := _generate(2, rng_seed)
		var floor_count := battle.field.cells().size() - _walls(battle).size()
		for enemy in battle.enemies():
			battle.field.remove_unit(enemy)

		var reachable := battle.field.reachable(player.position, 99)

		assert_eq(reachable.size(), floor_count, "seed %d" % rng_seed)


func test_同じシードなら同じ配置になる():
	var first := _generate(2, 5)
	var first_walls := _walls(first)
	var first_enemies := first.enemies().map(func(unit: Unit) -> Vector2i: return unit.position)

	var second := _generate(2, 5)

	assert_eq(_walls(second), first_walls)
	assert_eq(
		second.enemies().map(func(unit: Unit) -> Vector2i: return unit.position), first_enemies
	)


func test_シードが違えば配置が変わる():
	assert_ne(_walls(_generate(2, 5)), _walls(_generate(2, 6)))
