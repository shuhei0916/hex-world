extends GutTest


func _kinds(cards: Array[Card]) -> Array:
	return cards.map(func(card: Card) -> Card.Kind: return card.kind)


func test_初期デッキは移動と攻撃と防御を含む():
	var kinds := _kinds(CardLibrary.starter_cards())

	assert_has(kinds, Card.Kind.MOVE)
	assert_has(kinds, Card.Kind.ATTACK)
	assert_has(kinds, Card.Kind.BLOCK)


func test_初期デッキは呼ぶたびに別のカードで作られる():
	assert_ne(CardLibrary.starter_cards()[0], CardLibrary.starter_cards()[0])
