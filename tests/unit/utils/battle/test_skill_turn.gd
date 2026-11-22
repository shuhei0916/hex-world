extends GutTest

## 主人公の手番。マナを払ってスキルを使う。強いスキルは使うとしばらく使えない。

var field: Battlefield
var player: Unit
var enemy: Unit
var battle: Battle
var walk: Skill
var dash: Skill
var skill_turn: SkillTurn


func before_each():
	field = Battlefield.hexagon(5)
	player = Unit.new(Unit.Team.PLAYER, 10, 3)
	enemy = Unit.new(Unit.Team.ENEMY, 8, 2)
	field.place_unit(player, Vector2i(-5, 0))
	field.place_unit(enemy, Vector2i(5, 0))
	battle = Battle.new(field)
	walk = Skill.new("歩く", Skill.Kind.MOVE, 1)
	dash = Skill.new("走る", Skill.Kind.MOVE, 2, 2, 2)
	var skills: Array[Skill] = [walk, dash]
	skill_turn = SkillTurn.new(battle, skills)


func test_開始時はマナが満タンですべてのスキルが使える():
	assert_eq(skill_turn.energy, SkillTurn.ENERGY_PER_TURN)
	assert_true(skill_turn.can_use(walk))
	assert_true(skill_turn.can_use(dash))


func test_スキルを使うと行動してコストぶんマナが減る():
	var used := skill_turn.use(walk, Vector2i(-4, 0))

	assert_true(used)
	assert_eq(player.position, Vector2i(-4, 0))
	assert_eq(skill_turn.energy, SkillTurn.ENERGY_PER_TURN - 1)


func test_コストの重いスキルはそのぶんマナを使う():
	skill_turn.use(dash, Vector2i(-3, 0))

	assert_eq(skill_turn.energy, SkillTurn.ENERGY_PER_TURN - 2)


func test_クールダウンのないスキルは同じターンに何度でも使える():
	skill_turn.use(walk, Vector2i(-4, 0))

	var used := skill_turn.use(walk, Vector2i(-3, 0))

	assert_true(used)
	assert_eq(player.position, Vector2i(-3, 0))


func test_対象が不正ならマナもクールダウンも使わない():
	var used := skill_turn.use(dash, Vector2i(0, 0))

	assert_false(used)
	assert_eq(skill_turn.energy, SkillTurn.ENERGY_PER_TURN)
	assert_true(skill_turn.can_use(dash))


func test_マナが足りないスキルは使えない():
	skill_turn.use(walk, Vector2i(-4, 0))
	skill_turn.use(walk, Vector2i(-3, 0))

	assert_false(skill_turn.can_use(dash))
	assert_false(skill_turn.use(dash, Vector2i(-1, 0)))
	assert_eq(player.position, Vector2i(-3, 0))


func test_持っていないスキルは使えない():
	var stranger := Skill.new("歩く", Skill.Kind.MOVE, 1)

	assert_false(skill_turn.can_use(stranger))
	assert_false(skill_turn.use(stranger, Vector2i(-4, 0)))


func test_クールダウンのあるスキルは使うとそのターン数だけ使えない():
	skill_turn.use(dash, Vector2i(-3, 0))

	assert_eq(skill_turn.cooldown_left(dash), 2)
	assert_false(skill_turn.can_use(dash))
	assert_false(skill_turn.use(dash, Vector2i(-2, 0)))


func test_クールダウンはターンを終えるたびに1減り_0になると使える():
	skill_turn.use(dash, Vector2i(-3, 0))

	skill_turn.end_turn()

	assert_eq(skill_turn.cooldown_left(dash), 1)
	assert_false(skill_turn.can_use(dash))

	skill_turn.end_turn()

	assert_eq(skill_turn.cooldown_left(dash), 0)
	assert_true(skill_turn.can_use(dash))


func test_使っていないスキルのクールダウンは0():
	assert_eq(skill_turn.cooldown_left(dash), 0)


func test_ターンを終えるとマナが回復して敵が行動する():
	skill_turn.use(walk, Vector2i(-4, 0))

	skill_turn.end_turn()

	assert_eq(skill_turn.energy, SkillTurn.ENERGY_PER_TURN)
	assert_eq(battle.turn, 2)
	assert_ne(enemy.position, Vector2i(5, 0))
