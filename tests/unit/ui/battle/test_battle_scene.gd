# gdlint:disable=max-public-methods
extends GutTest

const BattleSceneScene := preload("res://scenes/ui/battle/battle_scene.tscn")

var field: Battlefield
var player: Unit
var enemy: Unit
var move_skill: Skill
var attack_skill: Skill
var scene: BattleScene


func before_each():
	field = Battlefield.hexagon(4)
	player = Unit.new(Unit.Team.PLAYER, 10, 3)
	enemy = Unit.new(Unit.Team.ENEMY, 5, 2)
	field.place_unit(player, Vector2i(0, 0))
	field.place_unit(enemy, Vector2i(1, 0))
	move_skill = Skill.new("歩く", Skill.Kind.MOVE, 2)
	attack_skill = Skill.new("斬る", Skill.Kind.ATTACK, 3)
	var skills: Array[Skill] = [move_skill, attack_skill]
	scene = BattleSceneScene.instantiate()
	scene.skill_turn = SkillTurn.new(Battle.new(field), skills)
	scene.animations_enabled = false
	add_child_autofree(scene)


func _bar() -> Node:
	return scene.get_node("Hud/SkillBar")


# 戦闘の途中で使えるスキルを足す
func _add_skill(skill: Skill) -> void:
	scene.skill_turn.skills.append(skill)
	scene.refresh()


func _button_of(skill: Skill) -> Button:
	return _bar().get_child(scene.skill_turn.skills.find(skill))


func _board() -> BoardView:
	return scene.get_node("Board")


func _pixel(hex: Vector2i) -> Vector2:
	return BattleHex.to_pixel(hex, BattleScene.HEX_SIZE)


func test_ユニットごとに表示が作られマスの位置に置かれる():
	assert_eq(scene.get_node("Units").get_child_count(), 2)
	assert_eq(scene.view_of(enemy).position, _pixel(Vector2i(1, 0)))


func test_使えるスキルの数だけボタンが並ぶ():
	assert_eq(_bar().get_child_count(), 2)


func test_スキルには名前とコストと効果が書かれる():
	var texts := _bar().get_children().map(func(button: Button) -> String: return button.text)

	assert_has(texts, "歩く (1)\n移動 2")
	assert_has(texts, "斬る (1)\n攻撃 3")


func test_スキルを選ぶ前は移動できるマスを示さない():
	assert_does_not_have(_board().reachable, Vector2i(0, 1))


func test_移動スキルを選ぶとその歩数で行けるマスを示す():
	scene.select_skill(move_skill)

	assert_has(_board().reachable, Vector2i(0, 2))
	assert_does_not_have(_board().reachable, Vector2i(0, 3))


func test_移動スキルを選んでマスをクリックすると移動する():
	scene.select_skill(move_skill)

	scene.click_hex(Vector2i(0, 2))

	assert_eq(player.position, Vector2i(0, 2))
	assert_eq(scene.view_of(player).position, _pixel(Vector2i(0, 2)))


func test_攻撃スキルを選んで敵をクリックすると攻撃する():
	scene.select_skill(attack_skill)

	scene.click_hex(Vector2i(1, 0))

	assert_eq(enemy.hp, 2)
	assert_eq(scene.view_of(enemy).get_node("HpLabel").text, "2")


func test_スキルを選ばずにクリックしても何も起きない():
	scene.click_hex(Vector2i(0, 2))

	assert_eq(player.position, Vector2i(0, 0))


func test_スキルを使ってもまだ使えるなら選んだままにする():
	scene.select_skill(move_skill)

	scene.click_hex(Vector2i(0, 2))

	assert_eq(scene.selected_skill, move_skill)
	assert_true(_button_of(move_skill).button_pressed)
	assert_has(_board().reachable, Vector2i(0, 4))


func test_選んだままのスキルは続けて使える():
	scene.select_skill(move_skill)
	scene.click_hex(Vector2i(0, 1))

	scene.click_hex(Vector2i(0, 2))

	assert_eq(player.position, Vector2i(0, 2))


func test_マナが足りなくなったスキルは選択が外れる():
	scene.select_skill(move_skill)
	scene.click_hex(Vector2i(0, 1))
	scene.click_hex(Vector2i(0, 2))

	scene.click_hex(Vector2i(0, 3))

	assert_null(scene.selected_skill)
	assert_does_not_have(_board().reachable, Vector2i(0, 4))


func test_クールダウンに入ったスキルは選択が外れる():
	var dash := Skill.new("走る", Skill.Kind.MOVE, 3, 1, 2)
	_add_skill(dash)
	scene.select_skill(dash)

	scene.click_hex(Vector2i(0, 3))

	assert_null(scene.selected_skill)


func test_選択を取り消せる():
	scene.select_skill(move_skill)

	scene.cancel_selection()

	assert_null(scene.selected_skill)
	assert_false(_button_of(move_skill).button_pressed)
	assert_does_not_have(_board().reachable, Vector2i(0, 1))


func test_別のスキルを選ぶと選択が移る():
	scene.select_skill(move_skill)

	scene.select_skill(attack_skill)

	assert_eq(scene.selected_skill, attack_skill)
	assert_does_not_have(_board().reachable, Vector2i(0, 1))


func test_選んだスキルをもう一度選ぶと選択が外れる():
	scene.select_skill(move_skill)

	scene.select_skill(move_skill)

	assert_null(scene.selected_skill)


func test_残りのマナを表示する():
	scene.select_skill(move_skill)
	scene.click_hex(Vector2i(0, 2))

	assert_string_contains(scene.get_node("Hud/EnergyLabel").text, "マナ: 2 / 3")


func test_マナが足りないスキルは押せない():
	var heavy := Skill.new("強打", Skill.Kind.ATTACK, 6, 4)

	_add_skill(heavy)

	assert_true(_button_of(heavy).disabled)
	assert_false(_button_of(move_skill).disabled)


func test_クールダウン中のスキルは押せず_使えるまでのターン数が書かれる():
	var dash := Skill.new("走る", Skill.Kind.MOVE, 3, 1, 2)
	_add_skill(dash)
	scene.select_skill(dash)

	scene.click_hex(Vector2i(0, 3))

	assert_true(_button_of(dash).disabled)
	assert_eq(_button_of(dash).text, "走る (1)\nあと2ターン")


func test_クールダウンが明けたスキルはまた押せる():
	field.place_unit(enemy, Vector2i(4, -4))
	var dash := Skill.new("走る", Skill.Kind.MOVE, 3, 1, 1)
	_add_skill(dash)
	scene.select_skill(dash)
	scene.click_hex(Vector2i(-3, 0))

	scene.end_turn()

	assert_false(_button_of(dash).disabled)
	assert_eq(_button_of(dash).text, "走る (1)\n移動 3")


func test_対象を選ばないスキルは選んだ時点で使う():
	var block_skill := Skill.new("守る", Skill.Kind.BLOCK, 4)
	_add_skill(block_skill)

	scene.select_skill(block_skill)

	assert_eq(player.block, 4)
	assert_null(scene.selected_skill)
	assert_string_contains(scene.get_node("Hud/EnergyLabel").text, "マナ: 2 / 3")


func test_ブロックがあるユニットにはその値を表示する():
	var block_skill := Skill.new("守る", Skill.Kind.BLOCK, 4)
	_add_skill(block_skill)

	scene.select_skill(block_skill)

	var label: Label = scene.view_of(player).get_node("BlockLabel")
	assert_true(label.visible)
	assert_eq(label.text, "4")


func test_ブロックがないユニットにはブロックを表示しない():
	assert_false(scene.view_of(player).get_node("BlockLabel").visible)


func test_ターン終了ボタンを押すと敵が行動してマナが回復し_選択が外れる():
	scene.select_skill(move_skill)
	scene.click_hex(Vector2i(0, 2))

	scene.get_node("Hud/EndTurnButton").pressed.emit()

	assert_eq(scene.battle.turn, 2)
	assert_string_contains(scene.get_node("Hud/EnergyLabel").text, "マナ: 3 / 3")
	assert_null(scene.selected_skill)
	assert_eq(scene.view_of(enemy).position, _pixel(enemy.position))
	assert_eq(BattleHex.distance(enemy.position, player.position), 1)


func test_倒した敵の表示は消える():
	enemy.take_damage(3)
	scene.select_skill(attack_skill)

	scene.click_hex(Vector2i(1, 0))

	assert_null(scene.view_of(enemy))


func test_戦闘中は決着を知らせない():
	watch_signals(scene)

	scene.select_skill(attack_skill)
	scene.click_hex(Vector2i(1, 0))

	assert_signal_not_emitted(scene, "battle_finished")


func test_勝利すると決着を知らせる():
	watch_signals(scene)
	enemy.take_damage(3)
	scene.select_skill(attack_skill)

	scene.click_hex(Vector2i(1, 0))

	assert_signal_emitted_with_parameters(scene, "battle_finished", [Battle.Outcome.VICTORY])


func test_敗北すると決着を知らせる():
	watch_signals(scene)
	player.take_damage(9)

	scene.end_turn()

	assert_signal_emitted_with_parameters(scene, "battle_finished", [Battle.Outcome.DEFEAT])


func test_決着は一度だけ知らせる():
	watch_signals(scene)
	enemy.take_damage(3)
	scene.select_skill(attack_skill)
	scene.click_hex(Vector2i(1, 0))

	scene.refresh()

	assert_signal_emit_count(scene, "battle_finished", 1)


func test_決着後はスキルとターン終了が押せない():
	enemy.take_damage(3)
	scene.select_skill(attack_skill)

	scene.click_hex(Vector2i(1, 0))

	assert_true(scene.get_node("Hud/EndTurnButton").disabled)
	for button: Button in _bar().get_children():
		assert_true(button.disabled)


func test_敵にマウスを乗せていなければ攻撃されうるマスも予定も示さない():
	assert_eq(_board().threatened.size(), 0)
	assert_eq(_board().plan_path.size(), 0)
	assert_eq(scene.get_node("Hud/IntentLabel").text, "")


func test_敵にマウスを乗せるとその敵に攻撃されうるマスを示す():
	scene.hover_hex(Vector2i(1, 0))

	assert_has(_board().threatened, Vector2i(0, 0))
	assert_has(_board().threatened, Vector2i(2, 0))


func test_マウスを乗せていない敵に攻撃されうるマスは示さない():
	var far_enemy := Unit.new(Unit.Team.ENEMY, 5, 2)
	field.place_unit(far_enemy, Vector2i(-4, 2))

	scene.hover_hex(Vector2i(1, 0))

	assert_does_not_have(_board().threatened, Vector2i(-3, 2))


func test_隣の敵にマウスを乗せると攻撃の予定を示す():
	scene.hover_hex(Vector2i(1, 0))

	assert_true(_board().plan_attacks)
	assert_eq(_board().plan_target, Vector2i(0, 0))
	assert_eq(scene.get_node("Hud/IntentLabel").text, "敵の予定: 攻撃（2ダメージ）")


func test_少し離れた敵にマウスを乗せると移動して攻撃する予定を経路つきで示す():
	field.place_unit(enemy, Vector2i(2, 0))

	scene.hover_hex(Vector2i(2, 0))

	assert_eq(_board().plan_path, [Vector2i(2, 0), Vector2i(1, 0)])
	assert_true(_board().plan_attacks)
	assert_eq(scene.get_node("Hud/IntentLabel").text, "敵の予定: 1マス移動して攻撃（2ダメージ）")


func test_遠い敵にマウスを乗せると移動だけの予定を示す():
	field.place_unit(enemy, Vector2i(4, 0))

	scene.hover_hex(Vector2i(4, 0))

	assert_eq(_board().plan_path.size(), 4)
	assert_false(_board().plan_attacks)
	assert_eq(scene.get_node("Hud/IntentLabel").text, "敵の予定: 3マス移動")


func test_敵からマウスを外すと攻撃されうるマスと予定を消す():
	scene.hover_hex(Vector2i(1, 0))

	scene.hover_hex(Vector2i(-2, 0))

	assert_eq(_board().threatened.size(), 0)
	assert_eq(_board().plan_path.size(), 0)
	assert_false(_board().plan_attacks)
	assert_eq(scene.get_node("Hud/IntentLabel").text, "")


func test_主人公にマウスを乗せても予定は示さない():
	scene.hover_hex(Vector2i(0, 0))

	assert_eq(scene.get_node("Hud/IntentLabel").text, "")
