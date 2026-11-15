class_name AttackAction
extends BattleAction
## 隣接する敵対ユニットを殴る。ダメージを指定しなければ攻撃力ぶんを与える。

const COST := 2

var target: Unit
var damage: int


func _init(p_actor: Unit, p_target: Unit, p_damage := -1) -> void:
	actor = p_actor
	target = p_target
	damage = p_damage if p_damage >= 0 else p_actor.attack_power


func cost(_battle: Battle) -> int:
	return COST


func can_perform(_battle: Battle) -> bool:
	return (
		target.is_alive()
		and target.team != actor.team
		and BattleHex.distance(actor.position, target.position) == 1
	)


func apply(battle: Battle) -> void:
	var lost := target.take_damage(damage)
	battle.unit_attacked.emit(actor, target, lost, target.hp, target.block)
