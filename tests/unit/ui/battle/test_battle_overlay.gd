extends GutTest

## 戦闘を、渡された場所（戦う chunk のある画面）に出し、決着の結果を見せてから閉じる。

var overlay: BattleOverlay
## 戦闘画面を置く場所。ゲームでは chunk を描いている World
var stage: Node2D
var player: Unit
var enemy: Unit
var attack_skill: Skill


func before_each():
	overlay = BattleOverlay.new()
	overlay.animations_enabled = false
	add_child_autofree(overlay)
	stage = Node2D.new()
	add_child_autofree(stage)
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
	overlay.open(_skill_turn(), stage)

	assert_true(overlay.is_open())
	assert_true(overlay.visible)
	assert_not_null(overlay.battle_scene)


func test_戦闘画面は渡した場所の原点に置かれる():
	overlay.open(_skill_turn(), stage)

	assert_eq(overlay.battle_scene.get_parent(), stage)
	assert_eq(overlay.battle_scene.position, Vector2.ZERO)


func test_裏の画面を隠す背景は持たない():
	overlay.open(_skill_turn(), stage)

	assert_null(overlay.get_node_or_null("Background"))


func test_戦闘画面は床やピースより手前に描かれる():
	overlay.open(_skill_turn(), stage)

	assert_gt(overlay.battle_scene.z_index, 10)


func test_勝ったときの結果のボタンは建設を始める():
	overlay.open(_skill_turn(), stage)

	_win()

	assert_eq(overlay.get_confirm_text(), "建設を始める")


func test_負けたときの結果のボタンは地図に戻る():
	overlay.open(_skill_turn(1), stage)

	overlay.battle_scene.end_turn()

	assert_eq(overlay.get_confirm_text(), "地図に戻る")


func test_閉じると戦闘画面は渡した場所から取り除かれる():
	overlay.open(_skill_turn(), stage)

	overlay.retreat()

	assert_eq(stage.get_child_count(), 0)


func test_結果の表示は盤面が透けない():
	overlay.open(_skill_turn(), stage)
	_win()

	var style: StyleBoxFlat = overlay.get_node("Ui/ResultPanel").get_theme_stylebox("panel")
	assert_eq(style.bg_color.a, 1.0)


func test_戦闘中は結果を出さない():
	overlay.open(_skill_turn(), stage)

	assert_false(overlay.is_result_shown())


func test_勝つと勝利の結果を出す():
	overlay.open(_skill_turn(), stage)

	_win()

	assert_true(overlay.is_result_shown())
	assert_string_contains(overlay.get_result_text(), "勝利")
	assert_signal_not_emitted(overlay, "closed")


func test_勝利の結果を閉じると勝ったことを知らせて閉じる():
	overlay.open(_skill_turn(), stage)
	_win()

	overlay.confirm_result()

	assert_signal_emitted_with_parameters(overlay, "closed", [true])
	assert_false(overlay.is_open())
	assert_false(overlay.visible)


func test_負けると敗北の結果を出し_閉じると負けたことを知らせる():
	overlay.open(_skill_turn(1), stage)

	overlay.battle_scene.end_turn()

	assert_string_contains(overlay.get_result_text(), "敗北")
	overlay.confirm_result()
	assert_signal_emitted_with_parameters(overlay, "closed", [false])


func test_撤退すると負けた扱いで閉じる():
	overlay.open(_skill_turn(), stage)

	overlay.retreat()

	assert_signal_emitted_with_parameters(overlay, "closed", [false])
	assert_false(overlay.is_open())


func test_決着したあとは撤退できない():
	overlay.open(_skill_turn(), stage)
	_win()

	overlay.retreat()

	assert_signal_not_emitted(overlay, "closed")
	assert_true(overlay.is_open())


func test_閉じたあとにもう一度開ける():
	overlay.open(_skill_turn(), stage)
	overlay.retreat()

	overlay.open(_skill_turn(), stage)

	assert_true(overlay.is_open())
	assert_false(overlay.is_result_shown())
