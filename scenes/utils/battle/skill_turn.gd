class_name SkillTurn
extends RefCounted
## 主人公の手番をスキルで行う方式。毎ターン回復するマナを払ってスキルを使う。
## クールダウンのあるスキルは、使うとしばらく使えない。

const ENERGY_PER_TURN := 3

var battle: Battle
## この戦闘で使えるスキル。
var skills: Array[Skill]
var energy: int

var _cooldowns: Dictionary[Skill, int] = {}


func _init(p_battle: Battle, p_skills: Array[Skill]) -> void:
	battle = p_battle
	skills = p_skills
	energy = ENERGY_PER_TURN


## いまスキルを使えるか（マナが足り、クールダウン中でない）。対象が正しいかは見ない。
func can_use(skill: Skill) -> bool:
	return skills.has(skill) and skill.cost <= energy and cooldown_left(skill) == 0


## スキルがもう一度使えるようになるまでに、あと何回ターンを終える必要があるか。
func cooldown_left(skill: Skill) -> int:
	return _cooldowns.get(skill, 0)


## スキルを hex を対象に使う。使えなければ何もせず false を返す。
func use(skill: Skill, hex: Vector2i) -> bool:
	if not can_use(skill):
		return false
	if not battle.execute(skill.create_action(battle.player, battle.field, hex)):
		return false
	energy -= skill.cost
	if skill.cooldown > 0:
		_cooldowns[skill] = skill.cooldown
	return true


func end_turn() -> void:
	battle.end_turn()
	for skill in _cooldowns.keys():
		_cooldowns[skill] -= 1
		if _cooldowns[skill] <= 0:
			_cooldowns.erase(skill)
	energy = ENERGY_PER_TURN
