class_name BlockAction
extends BattleAction
## 身を守ってブロックを得る。ブロックは受けるダメージを肩代わりする。

var amount: int


func _init(p_actor: Unit, p_amount: int) -> void:
	actor = p_actor
	amount = p_amount


func can_perform(_battle: Battle) -> bool:
	return amount > 0


func apply(_battle: Battle) -> void:
	actor.gain_block(amount)
