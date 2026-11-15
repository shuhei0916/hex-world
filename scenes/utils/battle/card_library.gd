class_name CardLibrary
## ゲームに登場するカードの一覧。呼ぶたびに新しいカードを作って返す。


## 最初から持っているデッキ。
static func starter_cards() -> Array[Card]:
	var cards: Array[Card] = []
	for i in range(4):
		cards.append(Card.new("歩く", Card.Kind.MOVE, 2))
	for i in range(3):
		cards.append(Card.new("斬る", Card.Kind.ATTACK, 3))
		cards.append(Card.new("守る", Card.Kind.BLOCK, 4))
	cards.append(Card.new("走る", Card.Kind.MOVE, 4, 2))
	cards.append(Card.new("強打", Card.Kind.ATTACK, 6, 2))
	return cards
