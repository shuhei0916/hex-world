class_name Deck
extends RefCounted
## 山札・手札・捨て札の3つの束。山札が尽きたら捨て札を切り直して山札にする。

var draw_pile: Array[Card] = []
var hand: Array[Card] = []
var discard_pile: Array[Card] = []

var _rng: RandomNumberGenerator


func _init(cards: Array[Card], rng: RandomNumberGenerator) -> void:
	_rng = rng
	draw_pile = cards.duplicate()
	_shuffle(draw_pile)


func draw(count: int) -> void:
	for i in range(count):
		if draw_pile.is_empty():
			draw_pile = discard_pile
			discard_pile = []
			_shuffle(draw_pile)
		if draw_pile.is_empty():
			return
		hand.append(draw_pile.pop_back())


func discard(card: Card) -> void:
	hand.erase(card)
	discard_pile.append(card)


func discard_hand() -> void:
	discard_pile.append_array(hand)
	hand.clear()


func _shuffle(pile: Array[Card]) -> void:
	Shuffle.in_place(pile, _rng)
