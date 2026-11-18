class_name SkillLibrary
## ゲームに登場するスキルの一覧。呼ぶたびに新しいスキルを作って返す。
## 最初から使えるスキルと、工場の研究（Research の effect "skill"）で解放するスキルがある。

## 研究で解放するスキル。{id: [名前, 種類, 値, マナ, クールダウン]}。値は仮。
const RESEARCH_SKILLS := {
	"iron_wall": ["鉄壁", Skill.Kind.BLOCK, 8, 1, 2],
	"steel_lance": ["鋼の槍", Skill.Kind.ATTACK, 6, 1, 1],
	"sprint": ["疾走", Skill.Kind.MOVE, 6, 1, 2],
}


## 最初から使えるスキル。
static func starter_skills() -> Array[Skill]:
	return [
		Skill.new("歩く", Skill.Kind.MOVE, 2),
		Skill.new("斬る", Skill.Kind.ATTACK, 3),
		Skill.new("守る", Skill.Kind.BLOCK, 4),
		Skill.new("走る", Skill.Kind.MOVE, 4, 1, 2),
		Skill.new("強打", Skill.Kind.ATTACK, 8, 2, 2),
	]


## 研究で解放するスキルを id から作る。知らない id なら null。
static func create(id: String) -> Skill:
	if not RESEARCH_SKILLS.has(id):
		return null
	var def: Array = RESEARCH_SKILLS[id]
	return Skill.new(def[0], def[1], def[2], def[3], def[4])


## 戦闘で使えるスキル。最初のスキルのあとに、解放済みのスキルを並べる。
static func available(unlocked_ids: Array) -> Array[Skill]:
	var skills := starter_skills()
	for id in unlocked_ids:
		var skill := create(id)
		if skill:
			skills.append(skill)
	return skills
