class_name MoveAction
extends BattleAction
## 目的地まで歩く。1マスにつき行動ポイントを1使う。

var destination: Vector2i
## 歩ける歩数の上限。負なら上限なし。
var max_steps: int


func _init(p_actor: Unit, p_destination: Vector2i, p_max_steps := -1) -> void:
	actor = p_actor
	destination = p_destination
	max_steps = p_max_steps


func cost(battle: Battle) -> int:
	return maxi(battle.field.find_path(actor.position, destination).size() - 1, 0)


func can_perform(battle: Battle) -> bool:
	var steps := cost(battle)
	return steps > 0 and (max_steps < 0 or steps <= max_steps)


func apply(battle: Battle) -> void:
	var path := battle.field.find_path(actor.position, destination)
	battle.field.place_unit(actor, destination)
	battle.unit_moved.emit(actor, path)
