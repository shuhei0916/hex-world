extends GutTest

## chunk を解放するための1戦。その chunk のマスが戦場になり、鉱床は通れない壁になる。
## 原点から遠い chunk ほど敵が手ごわい。

var chunk: Chunk


func before_each():
	chunk = Chunk.new()
	add_child_autofree(chunk)
	chunk.create_hex_grid(chunk.grid_radius)


func _create(chunk_hex: Vector2i) -> SkillTurn:
	var rng := RandomNumberGenerator.new()
	rng.seed = 1
	return ChunkBattle.create(chunk_hex, chunk, rng)


func test_原点の隣のchunkは最初の段階の敵と戦う():
	var battle := _create(Vector2i(1, 0)).battle

	assert_eq(battle.enemies().size(), Encounter.ENEMIES_BY_STAGE[0].size())


func test_原点から遠いchunkほど先の段階の敵と戦う():
	var battle := _create(Vector2i(3, 0)).battle

	assert_eq(battle.enemies().size(), Encounter.ENEMIES_BY_STAGE[2].size())


func test_段階の数より遠いchunkは最後の段階の敵と戦う():
	assert_eq(ChunkBattle.stage_for(Vector2i(9, 0)), Encounter.STAGE_COUNT)


func test_主人公は毎回HPが満タンで始まる():
	var player := _create(Vector2i(1, 0)).battle.player

	assert_eq(player.hp, ChunkBattle.PLAYER_MAX_HP)


func test_最初のスキルを持って始まる():
	var skill_turn := _create(Vector2i(1, 0))

	assert_eq(skill_turn.skills.size(), SkillLibrary.starter_skills().size())


func test_戦場のマスはchunkのマスと同じ():
	var field := _create(Vector2i(1, 0)).battle.field

	assert_eq(field.cells().size(), chunk.get_grid_hex_count())
	for hex in chunk.get_all_hexes():
		assert_true(field.has_cell(hex), str(hex))


func test_chunkの鉱床は通れない壁になる():
	chunk.mark_resource_hex(Vector2i(1, -1), "iron_ore")
	chunk.mark_resource_hex(Vector2i(2, -1), "iron_ore")

	var field := _create(Vector2i(1, 0)).battle.field

	assert_eq(field.terrain_at(Vector2i(1, -1)), Battlefield.Terrain.WALL)
	assert_eq(field.terrain_at(Vector2i(2, -1)), Battlefield.Terrain.WALL)
	assert_eq(field.terrain_at(Vector2i(0, 0)), Battlefield.Terrain.FLOOR)


func test_主人公はchunkに入ってきたマスから始まる():
	var rng := RandomNumberGenerator.new()
	rng.seed = 1
	var turn := ChunkBattle.create(Vector2i(1, 0), chunk, rng, Vector2i(-2, -3))
	assert_eq(turn.battle.player.position, Vector2i(-2, -3))
