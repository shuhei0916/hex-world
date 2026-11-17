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
