class_name EnemyAi
extends RefCounted
## 敵の行動を決める。主人公に隣接していれば攻撃し、そうでなければ近づく。


## unit が手番で行うことの予定を返す。ほかのユニットはいまの位置から動かないものとして見積もる。
func plan(battle: Battle, unit: Unit, ap := Battle.AP_PER_TURN) -> EnemyPlan:
	var target := battle.player
	var result := EnemyPlan.new()
	result.path = [unit.position]
	if BattleHex.distance(unit.position, target.position) > 1:
		var path := _path_to_adjacent(battle.field, unit.position, target.position)
		if path.is_empty():
			return result
		var steps := mini(ap, path.size() - 1)
		result.path = path.slice(0, steps + 1)
		ap -= steps
	result.attacks = (
		BattleHex.distance(result.path.back(), target.position) == 1 and ap >= AttackAction.COST
	)
	return result


## unit が次に取る行動を返す。できることがなければ null。
func next_action(battle: Battle, unit: Unit) -> BattleAction:
	var current := plan(battle, unit, battle.ap)
	if current.path.size() > 1:
		return MoveAction.new(unit, current.path.back())
	if current.attacks:
		return AttackAction.new(unit, battle.player)
	return null


## target の隣のマスのうち、最も少ない歩数で行けるマスまでの経路を返す。
func _path_to_adjacent(field: Battlefield, from: Vector2i, target: Vector2i) -> Array[Vector2i]:
	var best: Array[Vector2i] = []
	for hex in BattleHex.neighbors(target):
		var path := field.find_path(from, hex)
		if not path.is_empty() and (best.is_empty() or path.size() < best.size()):
			best = path
	return best
