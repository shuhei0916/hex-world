extends GutTest

## 戦闘画面をほかの画面の上に重ねて出し、決着の結果を見せてから閉じる。

var overlay: BattleOverlay
var player: Unit
var enemy: Unit
var attack_skill: Skill


func before_each():
	overlay = BattleOverlay.new()
	overlay.animations_enabled = false
	add_child_autofree(overlay)
	watch_signals(overlay)


# 主人公の隣に、攻撃スキル1枚で倒せる敵がいる戦闘
func _skill_turn(player_hp := 10) -> SkillTurn:
	var field := Battlefield.hexagon(3)
	player = Unit.new(Unit.Team.PLAYER, player_hp, 3)
	enemy = Unit.new(Unit.Team.ENEMY, 3, 5)
	field.place_unit(player, Vector2i(0, 0))
	field.place_unit(enemy, Vector2i(1, 0))
	attack_skill = Skill.new("斬る", Skill.Kind.ATTACK, 3)
	var skills: Array[Skill] = [attack_skill]
	return SkillTurn.new(Battle.new(field), skills)


func _win() -> void:
	overlay.battle_scene.select_skill(attack_skill)
	overlay.battle_scene.click_hex(enemy.position)


func test_はじめは閉じている():
	assert_false(overlay.is_open())
	assert_false(overlay.visible)


func test_開くと戦闘画面が出る():
	overlay.open(_skill_turn())

	assert_true(overlay.is_open())
	assert_true(overlay.visible)
	assert_not_null(overlay.battle_scene)


func test_盤面はスキルバーに隠れないよう_スキルバーの上の領域の中央に置く():
	overlay.open(_skill_turn())

	var size: Vector2 = overlay.get_viewport().get_visible_rect().size
	var expected := Vector2(size.x / 2.0, (size.y - BattleOverlay.SKILL_BAR_HEIGHT) / 2.0)
	assert_eq(overlay.battle_scene.position, expected)


func test_結果の表示は盤面が透けない():
	overlay.open(_skill_turn())
	_win()

	var style: StyleBoxFlat = overlay.get_node("Ui/ResultPanel").get_theme_stylebox("panel")
	assert_eq(style.bg_color.a, 1.0)


func test_戦闘中は結果を出さない():
	overlay.open(_skill_turn())

	assert_false(overlay.is_result_shown())


func test_勝つと勝利の結果を出す():
	overlay.open(_skill_turn())

	_win()

	assert_true(overlay.is_result_shown())
	assert_string_contains(overlay.get_result_text(), "勝利")
	assert_signal_not_emitted(overlay, "closed")


func test_勝利の結果を閉じると勝ったことを知らせて閉じる():
	overlay.open(_skill_turn())
	_win()

	overlay.confirm_result()

	assert_signal_emitted_with_parameters(overlay, "closed", [true])
	assert_false(overlay.is_open())
	assert_false(overlay.visible)


func test_負けると敗北の結果を出し_閉じると負けたことを知らせる():
	overlay.open(_skill_turn(1))

	overlay.battle_scene.end_turn()

	assert_string_contains(overlay.get_result_text(), "敗北")
	overlay.confirm_result()
	assert_signal_emitted_with_parameters(overlay, "closed", [false])


func test_撤退すると負けた扱いで閉じる():
	overlay.open(_skill_turn())

	overlay.retreat()

	assert_signal_emitted_with_parameters(overlay, "closed", [false])
	assert_false(overlay.is_open())


func test_決着したあとは撤退できない():
	overlay.open(_skill_turn())
	_win()

	overlay.retreat()

	assert_signal_not_emitted(overlay, "closed")
	assert_true(overlay.is_open())


func test_閉じたあとにもう一度開ける():
	overlay.open(_skill_turn())
	overlay.retreat()

	overlay.open(_skill_turn())

	assert_true(overlay.is_open())
	assert_false(overlay.is_result_shown())
