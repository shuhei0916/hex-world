class_name SkillLibrary
## ゲームに登場するスキルの一覧。呼ぶたびに新しいスキルを作って返す。


## 最初から使えるスキル。
static func starter_skills() -> Array[Skill]:
	return [
		Skill.new("歩く", Skill.Kind.MOVE, 2),
		Skill.new("斬る", Skill.Kind.ATTACK, 3),
		Skill.new("守る", Skill.Kind.BLOCK, 4),
		Skill.new("走る", Skill.Kind.MOVE, 4, 1, 2),
		Skill.new("強打", Skill.Kind.ATTACK, 8, 2, 2),
	]
