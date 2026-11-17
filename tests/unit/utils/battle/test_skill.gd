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


func test_移動スキルは値の歩数以内のマスへ移動させる():
	var skill := Skill.new("移動2", Skill.Kind.MOVE, 2)

	var moved := battle.execute(skill.create_action(player, field, Vector2i(0, 2)))

	assert_true(moved)
	assert_eq(player.position, Vector2i(0, 2))


func test_移動スキルは値より遠いマスへは移動させない():
	var skill := Skill.new("移動2", Skill.Kind.MOVE, 2)

	var moved := battle.execute(skill.create_action(player, field, Vector2i(0, 3)))

	assert_false(moved)
	assert_eq(player.position, Vector2i(0, 0))


func test_攻撃スキルは値ぶんのダメージを与える():
	var skill := Skill.new("強打", Skill.Kind.ATTACK, 5)

	var attacked := battle.execute(skill.create_action(player, field, Vector2i(1, 0)))

	assert_true(attacked)
	assert_eq(enemy.hp, 3)


func test_攻撃スキルは誰もいないマスには使えない():
	var skill := Skill.new("攻撃", Skill.Kind.ATTACK, 3)

	assert_null(skill.create_action(player, field, Vector2i(0, 1)))


func test_スキルによる行動は行動ポイントを使わない():
	var skill := Skill.new("強打", Skill.Kind.ATTACK, 5)

	battle.execute(skill.create_action(player, field, Vector2i(1, 0)))

	assert_eq(battle.ap, Battle.AP_PER_TURN)


func test_コストを指定しなければ1になる():
	assert_eq(Skill.new("歩く", Skill.Kind.MOVE, 2).cost, 1)
	assert_eq(Skill.new("走る", Skill.Kind.MOVE, 4, 2).cost, 2)


func test_防御スキルは値ぶんのブロックを得る():
	var skill := Skill.new("守る", Skill.Kind.BLOCK, 4)

	var blocked := battle.execute(skill.create_action(player, field, player.position))

	assert_true(blocked)
	assert_eq(player.block, 4)


func test_防御スキルは対象を選ばない():
	assert_false(Skill.new("守る", Skill.Kind.BLOCK, 4).needs_target())
	assert_true(Skill.new("歩く", Skill.Kind.MOVE, 2).needs_target())
	assert_true(Skill.new("斬る", Skill.Kind.ATTACK, 3).needs_target())


func test_スキルの説明は種類と値を表す():
	assert_eq(Skill.new("守る", Skill.Kind.BLOCK, 4).description(), "防御 4")
	assert_eq(Skill.new("強打", Skill.Kind.ATTACK, 5).description(), "攻撃 5")
	assert_eq(Skill.new("疾走", Skill.Kind.MOVE, 3).description(), "移動 3")


func test_クールダウンを指定しなければ0になる():
	assert_eq(Skill.new("歩く", Skill.Kind.MOVE, 2).cooldown, 0)
	assert_eq(Skill.new("強打", Skill.Kind.ATTACK, 8, 2, 3).cooldown, 3)
