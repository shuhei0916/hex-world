# gdlint:disable=max-public-methods
extends GutTest

const BattleSceneScene := preload("res://scenes/ui/battle/battle_scene.tscn")

var field: Battlefield
var player: Unit
var enemy: Unit
var move_card: Card
var attack_card: Card
var deck: Deck
var scene: BattleScene


func before_each():
	field = Battlefield.hexagon(4)
	player = Unit.new(Unit.Team.PLAYER, 10, 3)
	enemy = Unit.new(Unit.Team.ENEMY, 5, 2)
	field.place_unit(player, Vector2i(0, 0))
	field.place_unit(enemy, Vector2i(1, 0))
	move_card = Card.new("歩く", Card.Kind.MOVE, 2)
	attack_card = Card.new("斬る", Card.Kind.ATTACK, 3)
	var cards: Array[Card] = [
		move_card,
		attack_card,
		Card.new("歩く", Card.Kind.MOVE, 2),
		Card.new("斬る", Card.Kind.ATTACK, 3),
	]
	deck = Deck.new(cards, RandomNumberGenerator.new())
	scene = BattleSceneScene.instantiate()
	scene.card_turn = CardTurn.new(Battle.new(field), deck)
	scene.animations_enabled = false
	add_child_autofree(scene)


func _hand() -> Node:
	return scene.get_node("Hud/Hand")


func _board() -> BoardView:
	return scene.get_node("Board")


func _pixel(hex: Vector2i) -> Vector2:
	return BattleHex.to_pixel(hex, BattleScene.HEX_SIZE)


func test_ユニットごとに表示が作られマスの位置に置かれる():
	assert_eq(scene.get_node("Units").get_child_count(), 2)
	assert_eq(scene.view_of(enemy).position, _pixel(Vector2i(1, 0)))


func test_手札の枚数ぶんカードが並ぶ():
	assert_eq(_hand().get_child_count(), 4)


func test_カードには名前とコストと効果が書かれる():
	var texts := _hand().get_children().map(func(button: Button) -> String: return button.text)

	assert_has(texts, "歩く (1)\n移動 2")
	assert_has(texts, "斬る (1)\n攻撃 3")


func test_カードを選ぶ前は移動できるマスを示さない():
	assert_does_not_have(_board().reachable, Vector2i(0, 1))


func test_移動カードを選ぶとその歩数で行けるマスを示す():
	scene.select_card(move_card)

	assert_has(_board().reachable, Vector2i(0, 2))
	assert_does_not_have(_board().reachable, Vector2i(0, 3))


func test_移動カードを選んでマスをクリックすると移動する():
	scene.select_card(move_card)

	scene.click_hex(Vector2i(0, 2))

	assert_eq(player.position, Vector2i(0, 2))
	assert_eq(scene.view_of(player).position, _pixel(Vector2i(0, 2)))
	assert_eq(_hand().get_child_count(), 3)


func test_攻撃カードを選んで敵をクリックすると攻撃する():
	scene.select_card(attack_card)

	scene.click_hex(Vector2i(1, 0))

	assert_eq(enemy.hp, 2)
	assert_eq(scene.view_of(enemy).get_node("HpLabel").text, "2")


func test_カードを選ばずにクリックしても何も起きない():
	scene.click_hex(Vector2i(0, 2))

	assert_eq(player.position, Vector2i(0, 0))
	assert_eq(_hand().get_child_count(), 4)


func test_カードを使うと選択が外れる():
	scene.select_card(move_card)

	scene.click_hex(Vector2i(0, 2))

	assert_null(scene.selected_card)


func test_選んだカードをもう一度選ぶと選択が外れる():
	scene.select_card(move_card)

	scene.select_card(move_card)

	assert_null(scene.selected_card)


func test_残りのマナを表示する():
	scene.select_card(move_card)
	scene.click_hex(Vector2i(0, 2))

	assert_string_contains(scene.get_node("Hud/EnergyLabel").text, "マナ: 2 / 3")


func test_マナが足りないカードは押せない():
	var heavy := Card.new("強打", Card.Kind.ATTACK, 6, 4)
	deck.hand.append(heavy)

	scene.select_card(move_card)
	scene.select_card(move_card)

	var buttons := _hand().get_children().filter(
		func(button: Button) -> bool: return button.disabled
	)
	assert_eq(buttons.size(), 1)
	assert_string_contains(buttons[0].text, "強打")


func test_対象を選ばないカードは選んだ時点で使う():
	var block_card := Card.new("守る", Card.Kind.BLOCK, 4)
	deck.hand.append(block_card)

	scene.select_card(block_card)

	assert_eq(player.block, 4)
	assert_null(scene.selected_card)
	assert_does_not_have(deck.hand, block_card)


func test_ブロックがあるユニットにはその値を表示する():
	var block_card := Card.new("守る", Card.Kind.BLOCK, 4)
	deck.hand.append(block_card)

	scene.select_card(block_card)

	var label: Label = scene.view_of(player).get_node("BlockLabel")
	assert_true(label.visible)
	assert_eq(label.text, "4")


func test_ブロックがないユニットにはブロックを表示しない():
	assert_false(scene.view_of(player).get_node("BlockLabel").visible)


func test_ターン終了ボタンを押すと敵が行動して手札を引き直す():
	scene.select_card(move_card)
	scene.click_hex(Vector2i(0, 2))

	scene.get_node("Hud/EndTurnButton").pressed.emit()

	assert_eq(scene.battle.turn, 2)
	assert_eq(_hand().get_child_count(), 4)
	assert_eq(scene.view_of(enemy).position, _pixel(enemy.position))
	assert_eq(BattleHex.distance(enemy.position, player.position), 1)


func test_倒した敵の表示は消える():
	enemy.take_damage(3)
	scene.select_card(attack_card)

	scene.click_hex(Vector2i(1, 0))

	assert_null(scene.view_of(enemy))


func test_戦闘中は決着を知らせない():
	watch_signals(scene)

	scene.select_card(attack_card)
	scene.click_hex(Vector2i(1, 0))

	assert_signal_not_emitted(scene, "battle_finished")


func test_勝利すると決着を知らせる():
	watch_signals(scene)
	enemy.take_damage(3)
	scene.select_card(attack_card)

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
	scene.select_card(attack_card)
	scene.click_hex(Vector2i(1, 0))

	scene.refresh()

	assert_signal_emit_count(scene, "battle_finished", 1)


func test_決着後は手札のカードとターン終了が押せない():
	enemy.take_damage(3)
	scene.select_card(attack_card)

	scene.click_hex(Vector2i(1, 0))

	assert_true(scene.get_node("Hud/EndTurnButton").disabled)
	for button: Button in _hand().get_children():
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
