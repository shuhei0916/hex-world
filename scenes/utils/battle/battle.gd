class_name Battle
extends RefCounted
## 1戦の進行役。手番・行動ポイント・勝敗を管理し、行動を戦場に適用する。

## ユニットが path（出発マスと到着マスを含む）をたどって移動した。
signal unit_moved(unit: Unit, path: Array[Vector2i])
## attacker が target を攻撃してHPを damage 減らし、target のHPが hp_after、ブロックが block_after になった。
signal unit_attacked(attacker: Unit, target: Unit, damage: int, hp_after: int, block_after: int)
signal unit_died(unit: Unit)

enum Outcome { ONGOING, VICTORY, DEFEAT }

const AP_PER_TURN := 3

var field: Battlefield
var player: Unit
var acting_unit: Unit
var ap: int
var turn := 1

var _enemy_ai := EnemyAi.new()


func _init(p_field: Battlefield) -> void:
	field = p_field
	for unit in field.units():
		if unit.team == Unit.Team.PLAYER:
			player = unit
	_start_turn_of(player)


## 行動ポイントを払って行動を実行する。実行できなければ何もせず false を返す。
func perform(action: BattleAction) -> bool:
	if action == null:
		return false
	var cost := action.cost(self)
	if cost > ap or not execute(action):
		return false
	ap -= cost
	return true


## 行動ポイントを使わずに行動を実行する。スキルなど別の対価で行う行動に使う。
func execute(action: BattleAction) -> bool:
	if action == null or outcome() != Outcome.ONGOING or action.actor != acting_unit:
		return false
	if not action.can_perform(self):
		return false
	action.apply(self)
	_remove_dead_units()
	return true


## 主人公の手番を終える。敵が順に行動し、次のターンの主人公の手番になる。
func end_turn() -> void:
	for enemy in enemies():
		_start_turn_of(enemy)
		while true:
			var action := _enemy_ai.next_action(self, enemy)
			if action == null or not perform(action):
				break
	turn += 1
	_start_turn_of(player)


func enemies() -> Array[Unit]:
	return field.units().filter(func(unit: Unit) -> bool: return unit.team == Unit.Team.ENEMY)


## 主人公がそこでターンを終えると、次の敵ターンに enemy から攻撃されうるマスを返す。
func threatened_hexes_by(enemy: Unit) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for origin in field.reachable(enemy.position, AP_PER_TURN - AttackAction.COST):
		for hex in BattleHex.neighbors(origin):
			var standable := field.is_walkable(hex) or hex == player.position
			if standable and not result.has(hex):
				result.append(hex)
	return result


## 主人公がいまの位置でターンを終えた場合に、enemy が次の手番で行うことの予定を返す。
func plan_of(enemy: Unit) -> EnemyPlan:
	return _enemy_ai.plan(self, enemy)


func outcome() -> Outcome:
	if not player.is_alive():
		return Outcome.DEFEAT
	if enemies().is_empty():
		return Outcome.VICTORY
	return Outcome.ONGOING


func _start_turn_of(unit: Unit) -> void:
	acting_unit = unit
	unit.block = 0
	ap = AP_PER_TURN


func _remove_dead_units() -> void:
	for unit in field.units():
		if not unit.is_alive():
			field.remove_unit(unit)
			unit_died.emit(unit)
