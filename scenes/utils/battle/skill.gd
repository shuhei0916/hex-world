class_name Skill
extends RefCounted
## 主人公が戦闘で使うスキル。使うとマスを対象にした行動になる。

enum Kind { MOVE, ATTACK, BLOCK }

const KIND_NAMES: Dictionary[Kind, String] = {
	Kind.MOVE: "移動",
	Kind.ATTACK: "攻撃",
	Kind.BLOCK: "防御",
}

var title: String
var kind: Kind
## 移動なら歩ける歩数、攻撃なら与えるダメージ、防御なら得るブロック。
var value: int
## 使うのに必要なマナ。
var cost: int
## 使ってから、もう一度使えるようになるまでに終えるターンの数。0 なら同じターンに何度でも使える。
var cooldown: int


func _init(p_title: String, p_kind: Kind, p_value: int, p_cost := 1, p_cooldown := 0) -> void:
	title = p_title
	kind = p_kind
	value = p_value
	cost = p_cost
	cooldown = p_cooldown


func description() -> String:
	return "%s %d" % [KIND_NAMES[kind], value]


## 使うときにマスを選ぶ必要があるか。
func needs_target() -> bool:
	return kind != Kind.BLOCK


## actor が hex を対象にこのスキルを使うときの行動を返す。対象にならなければ null。
func create_action(actor: Unit, field: Battlefield, hex: Vector2i) -> BattleAction:
	if kind == Kind.MOVE:
		return MoveAction.new(actor, hex, value)
	if kind == Kind.BLOCK:
		return BlockAction.new(actor, value)
	var target := field.unit_at(hex)
	if target == null:
		return null
	return AttackAction.new(actor, target, value)
