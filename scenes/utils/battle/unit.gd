class_name Unit
extends RefCounted
## 戦場に立つ1体のユニット。

enum Team { PLAYER, ENEMY }

var team: Team
var max_hp: int
var hp: int
var attack_power: int
## 受けるダメージを肩代わりする値。自分のターンの開始時に消える。
var block := 0
var position: Vector2i


func _init(p_team: Team, p_max_hp: int, p_attack_power: int) -> void:
	team = p_team
	max_hp = p_max_hp
	hp = p_max_hp
	attack_power = p_attack_power


## ダメージを受ける。先にブロックが減り、超えたぶんだけHPが減る。実際に減ったHPを返す。
func take_damage(amount: int) -> int:
	var absorbed := mini(block, amount)
	block -= absorbed
	var lost := mini(hp, amount - absorbed)
	hp -= lost
	return lost


func gain_block(amount: int) -> void:
	block += amount


func is_alive() -> bool:
	return hp > 0
