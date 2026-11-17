extends GutTest

var field: Battlefield
var player: Unit
var enemy: Unit
var battle: Battle


func before_each():
	field = Battlefield.hexagon(5)
	player = Unit.new(Unit.Team.PLAYER, 10, 3)
	enemy = Unit.new(Unit.Team.ENEMY, 5, 2)
	field.place_unit(player, Vector2i(0, 0))


func _start_with_enemy_at(hex: Vector2i) -> void:
	field.place_unit(enemy, hex)
	battle = Battle.new(field)


func test_隣接している敵は主人公を攻撃する():
	_start_with_enemy_at(Vector2i(1, 0))

	battle.end_turn()

	assert_eq(player.hp, 8)
	assert_eq(enemy.position, Vector2i(1, 0))


func test_1歩で届く敵は近づいてから攻撃する():
	_start_with_enemy_at(Vector2i(2, 0))

	battle.end_turn()

	assert_eq(Hex.distance(enemy.position, player.position), 1)
	assert_eq(player.hp, 8)


func test_遠い敵は行動ポイントぶんだけ主人公に近づく():
	_start_with_enemy_at(Vector2i(5, 0))

	battle.end_turn()

	assert_eq(Hex.distance(enemy.position, player.position), 2)
	assert_eq(player.hp, 10)


func test_複数の敵がそれぞれ行動する():
	var another := Unit.new(Unit.Team.ENEMY, 5, 2)
	field.place_unit(another, Vector2i(-1, 0))
	_start_with_enemy_at(Vector2i(1, 0))

	battle.end_turn()

	assert_eq(player.hp, 6)


func test_囲まれて近づけない敵は動かない():
	for hex in Hex.neighbors(Vector2i(0, 0)):
		field.set_terrain(hex, Battlefield.Terrain.WALL)
	_start_with_enemy_at(Vector2i(3, 0))

	battle.end_turn()

	assert_eq(enemy.position, Vector2i(3, 0))


func test_敵の行動後は主人公の手番に戻る():
	_start_with_enemy_at(Vector2i(1, 0))

	battle.end_turn()

	assert_eq(battle.acting_unit, player)
	assert_eq(battle.ap, Battle.AP_PER_TURN)


func test_主人公が倒れると敗北し残りの敵は行動しない():
	player.take_damage(8)
	_start_with_enemy_at(Vector2i(1, 0))
	var another := Unit.new(Unit.Team.ENEMY, 5, 2)
	field.place_unit(another, Vector2i(4, 0))

	battle.end_turn()

	assert_eq(battle.outcome(), Battle.Outcome.DEFEAT)
	assert_eq(another.position, Vector2i(4, 0))


func test_敵の隣は次の敵ターンに攻撃されうるマス():
	_start_with_enemy_at(Vector2i(3, 0))

	var threatened := battle.threatened_hexes_by(enemy)

	assert_has(threatened, Vector2i(2, 0))


func test_敵が1歩動いてから攻撃できるマスも攻撃されうる():
	_start_with_enemy_at(Vector2i(3, 0))

	var threatened := battle.threatened_hexes_by(enemy)

	assert_has(threatened, Vector2i(1, 0))
	assert_does_not_have(threatened, Vector2i(-1, 0))


func test_壁と敵自身のいるマスは攻撃されうるマスに含まない():
	field.set_terrain(Vector2i(2, 0), Battlefield.Terrain.WALL)
	_start_with_enemy_at(Vector2i(3, 0))

	var threatened := battle.threatened_hexes_by(enemy)

	assert_does_not_have(threatened, Vector2i(2, 0))
	assert_does_not_have(threatened, Vector2i(3, 0))


func test_主人公のいるマスも攻撃されうるなら含む():
	_start_with_enemy_at(Vector2i(2, 0))

	assert_has(battle.threatened_hexes_by(enemy), Vector2i(0, 0))


func test_ブロックは敵ターンの攻撃を防ぐ():
	_start_with_enemy_at(Vector2i(1, 0))
	player.gain_block(4)

	battle.end_turn()

	assert_eq(player.hp, 10)


func test_使い残したブロックは次の自分のターンの開始時に消える():
	_start_with_enemy_at(Vector2i(1, 0))
	player.gain_block(4)

	battle.end_turn()

	assert_eq(player.block, 0)


func test_攻撃されうるマスは敵ごとに求める():
	var another := Unit.new(Unit.Team.ENEMY, 5, 2)
	field.place_unit(another, Vector2i(-4, 0))
	_start_with_enemy_at(Vector2i(4, 0))

	var threatened := battle.threatened_hexes_by(enemy)

	assert_has(threatened, Vector2i(3, 0))
	assert_does_not_have(threatened, Vector2i(-3, 0))


func test_隣接している敵の予定はその場での攻撃():
	_start_with_enemy_at(Vector2i(1, 0))

	var plan := battle.plan_of(enemy)

	assert_eq(plan.path, [Vector2i(1, 0)])
	assert_true(plan.attacks)


func test_1歩で届く敵の予定は近づいて攻撃():
	_start_with_enemy_at(Vector2i(2, 0))

	var plan := battle.plan_of(enemy)

	assert_eq(plan.path, [Vector2i(2, 0), Vector2i(1, 0)])
	assert_true(plan.attacks)


func test_遠い敵の予定は行動ポイントぶんの移動のみ():
	_start_with_enemy_at(Vector2i(5, 0))

	var plan := battle.plan_of(enemy)

	assert_eq(plan.path.size(), 4)
	assert_false(plan.attacks)


func test_近づけない敵の予定は動かず攻撃もしない():
	for hex in Hex.neighbors(Vector2i(0, 0)):
		field.set_terrain(hex, Battlefield.Terrain.WALL)
	_start_with_enemy_at(Vector2i(3, 0))

	var plan := battle.plan_of(enemy)

	assert_eq(plan.path, [Vector2i(3, 0)])
	assert_false(plan.attacks)


func test_敵は予定どおりの場所まで動く():
	_start_with_enemy_at(Vector2i(4, -2))
	var plan := battle.plan_of(enemy)

	battle.end_turn()

	assert_eq(enemy.position, plan.path.back())
