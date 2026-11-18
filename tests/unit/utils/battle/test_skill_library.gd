extends GutTest


func _kinds(skills: Array[Skill]) -> Array:
	return skills.map(func(skill: Skill) -> Skill.Kind: return skill.kind)


func test_最初のスキルは移動と攻撃と防御を含む():
	var kinds := _kinds(SkillLibrary.starter_skills())

	assert_has(kinds, Skill.Kind.MOVE)
	assert_has(kinds, Skill.Kind.ATTACK)
	assert_has(kinds, Skill.Kind.BLOCK)


func test_最初のスキルは呼ぶたびに別のスキルで作られる():
	assert_ne(SkillLibrary.starter_skills()[0], SkillLibrary.starter_skills()[0])


func test_最初のスキルに同じ名前のものはない():
	var titles := {}
	for skill in SkillLibrary.starter_skills():
		titles[skill.title] = true

	assert_eq(titles.size(), SkillLibrary.starter_skills().size())


func test_最初のスキルにはクールダウンのあるものとないものがある():
	var cooldowns := SkillLibrary.starter_skills().map(
		func(skill: Skill) -> bool: return skill.cooldown > 0
	)

	assert_has(cooldowns, true)
	assert_has(cooldowns, false)


func test_研究で解放するスキルをidで作れる():
	for id in SkillLibrary.RESEARCH_SKILLS:
		var skill := SkillLibrary.create(id)
		assert_not_null(skill, id)
		if skill:
			assert_ne(skill.title, "", id)


func test_知らないidのスキルはnull():
	assert_null(SkillLibrary.create("unknown"))


func test_研究で解放するスキルは最初のスキルと名前が重ならない():
	var titles := {}
	for skill in SkillLibrary.starter_skills():
		titles[skill.title] = true
	for id in SkillLibrary.RESEARCH_SKILLS:
		assert_false(titles.has(SkillLibrary.create(id).title), id)


func test_使えるスキルは最初のスキルに解放済みのスキルを足したもの():
	var id: String = SkillLibrary.RESEARCH_SKILLS.keys()[0]
	var skills := SkillLibrary.available([id])

	assert_eq(skills.size(), SkillLibrary.starter_skills().size() + 1)
	assert_eq(skills[-1].title, SkillLibrary.create(id).title)


func test_何も解放していなければ使えるのは最初のスキルだけ():
	assert_eq(SkillLibrary.available([]).size(), SkillLibrary.starter_skills().size())
