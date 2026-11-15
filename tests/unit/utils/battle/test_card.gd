extends GutTest

var field: Battlefield
var player: Unit
var enemy: Unit
var battle: Battle


func before_each():
	field = Battlefield.hexagon(4)
	player = Unit.new(Unit.Team.PLAYER, 10, 3)
	enemy = Unit.new(Unit.Team.ENEMY, 8, 2)
	field.place_unit(player, Vector2i(0, 0))
	field.place_unit(enemy, Vector2i(1, 0))
	battle = Battle.new(field)


func test_移動カードは値の歩数以内のマスへ移動させる():
	var card := Card.new("移動2", Card.Kind.MOVE, 2)

	var moved := battle.execute(card.create_action(player, field, Vector2i(0, 2)))

	assert_true(moved)
	assert_eq(player.position, Vector2i(0, 2))


func test_移動カードは値より遠いマスへは移動させない():
	var card := Card.new("移動2", Card.Kind.MOVE, 2)

	var moved := battle.execute(card.create_action(player, field, Vector2i(0, 3)))

	assert_false(moved)
	assert_eq(player.position, Vector2i(0, 0))


func test_攻撃カードは値ぶんのダメージを与える():
	var card := Card.new("強打", Card.Kind.ATTACK, 5)

	var attacked := battle.execute(card.create_action(player, field, Vector2i(1, 0)))

	assert_true(attacked)
	assert_eq(enemy.hp, 3)


func test_攻撃カードは誰もいないマスには使えない():
	var card := Card.new("攻撃", Card.Kind.ATTACK, 3)

	assert_null(card.create_action(player, field, Vector2i(0, 1)))


func test_カードによる行動は行動ポイントを使わない():
	var card := Card.new("強打", Card.Kind.ATTACK, 5)

	battle.execute(card.create_action(player, field, Vector2i(1, 0)))

	assert_eq(battle.ap, Battle.AP_PER_TURN)


func test_コストを指定しなければ1になる():
	assert_eq(Card.new("歩く", Card.Kind.MOVE, 2).cost, 1)
	assert_eq(Card.new("走る", Card.Kind.MOVE, 4, 2).cost, 2)


func test_防御カードは値ぶんのブロックを得る():
	var card := Card.new("守る", Card.Kind.BLOCK, 4)

	var blocked := battle.execute(card.create_action(player, field, player.position))

	assert_true(blocked)
	assert_eq(player.block, 4)


func test_防御カードは対象を選ばない():
	assert_false(Card.new("守る", Card.Kind.BLOCK, 4).needs_target())
	assert_true(Card.new("歩く", Card.Kind.MOVE, 2).needs_target())
	assert_true(Card.new("斬る", Card.Kind.ATTACK, 3).needs_target())


func test_カードの説明は種類と値を表す():
	assert_eq(Card.new("守る", Card.Kind.BLOCK, 4).description(), "防御 4")
	assert_eq(Card.new("強打", Card.Kind.ATTACK, 5).description(), "攻撃 5")
	assert_eq(Card.new("疾走", Card.Kind.MOVE, 3).description(), "移動 3")
