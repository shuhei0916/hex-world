extends GutTest

var field: Battlefield
var player: Unit
var enemy: Unit
var battle: Battle
var deck: Deck
var card_turn: CardTurn


func before_each():
	field = Battlefield.hexagon(5)
	player = Unit.new(Unit.Team.PLAYER, 10, 3)
	enemy = Unit.new(Unit.Team.ENEMY, 8, 2)
	field.place_unit(player, Vector2i(0, 0))
	field.place_unit(enemy, Vector2i(5, 0))
	battle = Battle.new(field)
	var cards: Array[Card] = []
	for i in range(10):
		cards.append(Card.new("移動", Card.Kind.MOVE, 2))
	var rng := RandomNumberGenerator.new()
	rng.seed = 1
	deck = Deck.new(cards, rng)
	card_turn = CardTurn.new(battle, deck)


func test_開始時に手札を引いてマナが満タンになる():
	assert_eq(deck.hand.size(), CardTurn.HAND_SIZE)
	assert_eq(card_turn.energy, CardTurn.ENERGY_PER_TURN)


func test_カードを使うと行動して捨て札に移りコストぶんマナが減る():
	var card := deck.hand[0]

	var played := card_turn.play(card, Vector2i(2, 0))

	assert_true(played)
	assert_eq(player.position, Vector2i(2, 0))
	assert_does_not_have(deck.hand, card)
	assert_has(deck.discard_pile, card)
	assert_eq(card_turn.energy, CardTurn.ENERGY_PER_TURN - 1)


func test_コストの重いカードはそのぶんマナを使う():
	var heavy := Card.new("走る", Card.Kind.MOVE, 4, 2)
	deck.hand.append(heavy)

	card_turn.play(heavy, Vector2i(4, 0))

	assert_eq(card_turn.energy, CardTurn.ENERGY_PER_TURN - 2)


func test_対象が不正ならカードは手札に残る():
	var card := deck.hand[0]

	var played := card_turn.play(card, Vector2i(4, 0))

	assert_false(played)
	assert_has(deck.hand, card)
	assert_eq(card_turn.energy, CardTurn.ENERGY_PER_TURN)


func test_マナが足りないカードは使えない():
	var heavy := Card.new("走る", Card.Kind.MOVE, 4, 2)
	deck.hand.append(heavy)
	card_turn.play(deck.hand[0], Vector2i(1, 0))
	card_turn.play(deck.hand[0], Vector2i(2, 0))

	var played := card_turn.play(heavy, Vector2i(3, 0))

	assert_false(played)
	assert_eq(player.position, Vector2i(2, 0))
	assert_has(deck.hand, heavy)


func test_手札にないカードは使えない():
	var stranger := Card.new("移動", Card.Kind.MOVE, 2)

	assert_false(card_turn.play(stranger, Vector2i(1, 0)))


func test_ターンを終えると手札を捨てて引き直しマナが回復して敵が行動する():
	card_turn.play(deck.hand[0], Vector2i(1, 0))
	var old_hand := deck.hand.duplicate()

	card_turn.end_turn()

	assert_eq(deck.hand.size(), CardTurn.HAND_SIZE)
	for card in old_hand:
		assert_does_not_have(deck.hand, card)
	assert_eq(card_turn.energy, CardTurn.ENERGY_PER_TURN)
	assert_eq(battle.turn, 2)
	assert_ne(enemy.position, Vector2i(5, 0))
