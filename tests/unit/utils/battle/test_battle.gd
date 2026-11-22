extends GutTest

var field: Battlefield
var player: Unit
var enemy: Unit
var battle: Battle


func before_each():
	field = Battlefield.hexagon(4)
	player = Unit.new(Unit.Team.PLAYER, 10, 3)
	enemy = Unit.new(Unit.Team.ENEMY, 5, 2)
	field.place_unit(player, Vector2i(0, 0))
	field.place_unit(enemy, Vector2i(3, 0))
	battle = Battle.new(field)


func test_開始時は主人公の手番で行動ポイントは満タン():
	assert_eq(battle.acting_unit, player)
	assert_eq(battle.ap, Battle.AP_PER_TURN)


func test_移動すると歩数ぶんの行動ポイントを使って位置が変わる():
	var moved := battle.perform(MoveAction.new(player, Vector2i(2, 0)))

	assert_true(moved)
	assert_eq(player.position, Vector2i(2, 0))
	assert_eq(battle.ap, Battle.AP_PER_TURN - 2)


func test_行動ポイントが足りない移動はできない():
	var moved := battle.perform(MoveAction.new(player, Vector2i(-4, 0)))

	assert_false(moved)
	assert_eq(player.position, Vector2i(0, 0))
	assert_eq(battle.ap, Battle.AP_PER_TURN)


func test_通行できないマスへは移動できない():
	assert_false(battle.perform(MoveAction.new(player, Vector2i(3, 0))))
	assert_false(battle.perform(MoveAction.new(player, Vector2i(9, 9))))
	assert_false(battle.perform(MoveAction.new(player, Vector2i(0, 0))))


func test_隣接する敵を攻撃すると攻撃力ぶんのダメージを与える():
	field.place_unit(enemy, Vector2i(1, 0))

	var attacked := battle.perform(AttackAction.new(player, enemy))

	assert_true(attacked)
	assert_eq(enemy.hp, 2)
	assert_eq(battle.ap, Battle.AP_PER_TURN - AttackAction.COST)


func test_離れた敵は攻撃できない():
	assert_false(battle.perform(AttackAction.new(player, enemy)))
	assert_eq(enemy.hp, 5)


func test_味方は攻撃できない():
	assert_false(battle.perform(AttackAction.new(player, player)))


func test_行動ポイントが足りない攻撃はできない():
	field.place_unit(enemy, Vector2i(1, 0))
	battle.perform(AttackAction.new(player, enemy))

	assert_false(battle.perform(AttackAction.new(player, enemy)))
	assert_eq(enemy.hp, 2)


func test_手番でないユニットは行動できない():
	assert_false(battle.perform(MoveAction.new(enemy, Vector2i(2, 0))))


func test_倒されたユニットは戦場から取り除かれる():
	enemy.take_damage(3)
	field.place_unit(enemy, Vector2i(1, 0))

	battle.perform(AttackAction.new(player, enemy))

	assert_null(field.unit_at(Vector2i(1, 0)))


func test_敵がいるあいだは戦闘継続():
	assert_eq(battle.outcome(), Battle.Outcome.ONGOING)


func test_敵を全滅させると勝利():
	enemy.take_damage(3)
	field.place_unit(enemy, Vector2i(1, 0))

	battle.perform(AttackAction.new(player, enemy))

	assert_eq(battle.outcome(), Battle.Outcome.VICTORY)


func test_決着後は行動できない():
	enemy.take_damage(3)
	field.place_unit(enemy, Vector2i(1, 0))
	battle.perform(AttackAction.new(player, enemy))

	assert_false(battle.perform(MoveAction.new(player, Vector2i(0, 1))))


func test_ターンを終えると行動ポイントが回復してターン数が進む():
	battle.perform(MoveAction.new(player, Vector2i(1, 0)))

	battle.end_turn()

	assert_eq(battle.acting_unit, player)
	assert_eq(battle.ap, Battle.AP_PER_TURN)
	assert_eq(battle.turn, 2)
