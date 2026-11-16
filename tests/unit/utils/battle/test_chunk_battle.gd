extends GutTest

## chunk を解放するための1戦。原点から遠い chunk ほど敵が手ごわい。


func _create(chunk_hex: Hex) -> CardTurn:
	var rng := RandomNumberGenerator.new()
	rng.seed = 1
	return ChunkBattle.create(chunk_hex, rng)


func test_原点の隣のchunkは最初の段階の敵と戦う():
	var battle := _create(Hex.new(1, 0)).battle

	assert_eq(battle.enemies().size(), Encounter.ENEMIES_BY_STAGE[0].size())


func test_原点から遠いchunkほど先の段階の敵と戦う():
	var battle := _create(Hex.new(3, 0)).battle

	assert_eq(battle.enemies().size(), Encounter.ENEMIES_BY_STAGE[2].size())


func test_段階の数より遠いchunkは最後の段階の敵と戦う():
	assert_eq(ChunkBattle.stage_for(Hex.new(9, 0)), Encounter.STAGE_COUNT)


func test_主人公は毎回HPが満タンで始まる():
	var player := _create(Hex.new(1, 0)).battle.player

	assert_eq(player.hp, ChunkBattle.PLAYER_MAX_HP)


func test_初期デッキから手札を引いた状態で始まる():
	var card_turn := _create(Hex.new(1, 0))

	assert_eq(card_turn.deck.hand.size(), CardTurn.HAND_SIZE)
