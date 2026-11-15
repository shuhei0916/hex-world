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
	field.place_unit(enemy, Vector2i(1, 0))
	battle = Battle.new(field)
	watch_signals(battle)


func test_移動すると通った経路つきで知らせる():
	battle.perform(MoveAction.new(player, Vector2i(0, 2)))

	var expected_path: Array[Vector2i] = [Vector2i(0, 0), Vector2i(0, 1), Vector2i(0, 2)]
	assert_signal_emitted_with_parameters(battle, "unit_moved", [player, expected_path])


func test_攻撃すると減らしたHPと攻撃後のHPとブロックつきで知らせる():
	battle.perform(AttackAction.new(player, enemy))

	assert_signal_emitted_with_parameters(battle, "unit_attacked", [player, enemy, 3, 2, 0])


func test_ブロックで防がれた攻撃は減らしたHPを0として知らせる():
	enemy.gain_block(5)

	battle.perform(AttackAction.new(player, enemy))

	assert_signal_emitted_with_parameters(battle, "unit_attacked", [player, enemy, 0, 5, 2])


func test_倒すと死亡を知らせる():
	enemy.take_damage(3)

	battle.perform(AttackAction.new(player, enemy))

	assert_signal_emitted_with_parameters(battle, "unit_died", [enemy])


func test_倒していなければ死亡を知らせない():
	battle.perform(AttackAction.new(player, enemy))

	assert_signal_not_emitted(battle, "unit_died")


func test_実行できなかった行動は知らせない():
	battle.perform(MoveAction.new(player, Vector2i(1, 0)))

	assert_signal_not_emitted(battle, "unit_moved")


func test_敵ターンの行動も知らせる():
	battle.end_turn()

	assert_signal_emitted_with_parameters(battle, "unit_attacked", [enemy, player, 2, 8, 0])
