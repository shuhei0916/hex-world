extends GutTest

var cards: Array[Card]
var deck: Deck


func before_each():
	cards = []
	for i in range(5):
		cards.append(Card.new("移動%d" % i, Card.Kind.MOVE, 2))
	var rng := RandomNumberGenerator.new()
	rng.seed = 1
	deck = Deck.new(cards, rng)


func test_はじめは全カードが山札にある():
	assert_eq(deck.draw_pile.size(), 5)
	assert_eq(deck.hand.size(), 0)
	assert_eq(deck.discard_pile.size(), 0)


func test_引いた枚数だけ山札から手札に移る():
	deck.draw(3)

	assert_eq(deck.hand.size(), 3)
	assert_eq(deck.draw_pile.size(), 2)


func test_手札のカードを捨てると捨て札に移る():
	deck.draw(3)
	var card := deck.hand[0]

	deck.discard(card)

	assert_does_not_have(deck.hand, card)
	assert_eq(deck.discard_pile, [card])


func test_手札をすべて捨てられる():
	deck.draw(3)

	deck.discard_hand()

	assert_eq(deck.hand.size(), 0)
	assert_eq(deck.discard_pile.size(), 3)


func test_山札が尽きたら捨て札を山札に戻して引く():
	deck.draw(4)
	deck.discard_hand()

	deck.draw(3)

	assert_eq(deck.hand.size(), 3)
	assert_eq(deck.draw_pile.size(), 2)
	assert_eq(deck.discard_pile.size(), 0)


func test_山札も捨て札もなければ引けるぶんだけ引く():
	deck.draw(8)

	assert_eq(deck.hand.size(), 5)


func test_同じシードなら同じ順に引く():
	var rng := RandomNumberGenerator.new()
	rng.seed = 1
	var other := Deck.new(cards, rng)

	deck.draw(5)
	other.draw(5)

	assert_eq(deck.hand, other.hand)
