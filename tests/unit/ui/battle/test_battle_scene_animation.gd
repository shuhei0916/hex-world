extends GutTest

const BattleSceneScene := preload("res://scenes/ui/battle/battle_scene.tscn")

var field: Battlefield
var player: Unit
var enemy: Unit
var move_card: Card
var attack_card: Card
var scene: BattleScene


func before_each():
	field = Battlefield.hexagon(4)
	player = Unit.new(Unit.Team.PLAYER, 10, 3)
	enemy = Unit.new(Unit.Team.ENEMY, 5, 2)
	field.place_unit(player, Vector2i(0, 0))
	field.place_unit(enemy, Vector2i(1, 0))
	move_card = Card.new("歩く", Card.Kind.MOVE, 2)
	attack_card = Card.new("斬る", Card.Kind.ATTACK, 3)
	var cards: Array[Card] = [move_card, attack_card, Card.new("歩く", Card.Kind.MOVE, 2)]
	scene = BattleSceneScene.instantiate()
	scene.card_turn = CardTurn.new(Battle.new(field), Deck.new(cards, RandomNumberGenerator.new()))
	add_child_autofree(scene)


func _move_to(hex: Vector2i) -> void:
	scene.select_card(move_card)
	scene.click_hex(hex)


func _attack(hex: Vector2i) -> void:
	scene.select_card(attack_card)
	scene.click_hex(hex)


func _pixel(hex: Vector2i) -> Vector2:
	return BattleHex.to_pixel(hex, BattleScene.HEX_SIZE)


func test_何もしていなければアニメーション中ではない():
	assert_false(scene.is_animating)


func test_移動した直後はアニメーション中で表示はまだ元の位置にある():
	_move_to(Vector2i(0, 2))

	assert_true(scene.is_animating)
	assert_eq(scene.view_of(player).position, _pixel(Vector2i(0, 0)))


func test_移動のアニメーションが終わると表示は移動先にある():
	_move_to(Vector2i(0, 2))

	await wait_for_signal(scene.animations_finished, 3)

	assert_false(scene.is_animating)
	assert_eq(scene.view_of(player).position, _pixel(Vector2i(0, 2)))


func test_アニメーション中のクリックは無視する():
	_move_to(Vector2i(0, 2))

	scene.select_card(scene.card_turn.deck.hand[0])
	scene.click_hex(Vector2i(0, 1))
	await wait_for_signal(scene.animations_finished, 3)

	assert_eq(player.position, Vector2i(0, 2))


func test_アニメーション中はターンを終えられない():
	_move_to(Vector2i(0, 2))

	scene.end_turn()

	assert_eq(scene.battle.turn, 1)
	assert_true(scene.get_node("Hud/EndTurnButton").disabled)


func test_アニメーションが終わるとターン終了ボタンが押せる():
	_move_to(Vector2i(0, 2))

	await wait_for_signal(scene.animations_finished, 3)

	assert_false(scene.get_node("Hud/EndTurnButton").disabled)


func test_攻撃のアニメーションが終わるとHPの表示が減り攻撃側は元の位置に戻る():
	_attack(Vector2i(1, 0))

	await wait_for_signal(scene.animations_finished, 3)

	assert_eq(scene.view_of(enemy).get_node("HpLabel").text, "2")
	assert_eq(scene.view_of(player).position, _pixel(Vector2i(0, 0)))


func test_倒した敵の表示はアニメーションが終わるまで残りその後消える():
	enemy.take_damage(3)

	_attack(Vector2i(1, 0))

	assert_not_null(scene.view_of(enemy))
	await wait_for_signal(scene.animations_finished, 3)
	assert_null(scene.view_of(enemy))


func test_敵ターンの行動もアニメーションする():
	field.place_unit(enemy, Vector2i(4, 0))
	var shown_before := scene.view_of(enemy).position

	scene.end_turn()

	assert_true(scene.is_animating)
	assert_eq(scene.view_of(enemy).position, shown_before)
	await wait_for_signal(scene.animations_finished, 3)
	assert_eq(scene.view_of(enemy).position, _pixel(enemy.position))
	assert_eq(scene.battle.turn, 2)


func test_行動できなかったクリックではアニメーションしない():
	scene.click_hex(Vector2i(9, 9))

	assert_false(scene.is_animating)
