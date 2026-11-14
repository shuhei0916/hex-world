extends GutTest


func test_レシピデータを初期化できる():
	var recipe = Recipe.new("iron_ingot_smelting", {"iron_ore": 1}, {"iron_ingot": 1}, 2.0)

	assert_eq(recipe.id, "iron_ingot_smelting")
	assert_eq(recipe.inputs["iron_ore"], 1)
	assert_eq(recipe.outputs["iron_ingot"], 1)
	assert_eq(recipe.craft_time, 2.0)


func test_レシピデータベースからIDでレシピを取得できる():
	# RecipeDB はシングルトンか静的クラスを想定
	Recipe.RecipeDB._static_init()
	var recipe = Recipe.RecipeDB.get_recipe("iron_ingot")
	assert_not_null(recipe, "レシピが取得できるべき")
	assert_eq(recipe.inputs.size(), 1, "入力アイテムは1つであるべき")


func test_TypeでSmelterのレシピ一覧を取得できる():
	Recipe.RecipeDB._static_init()
	var smelter_recipes = Recipe.RecipeDB.get_recipes_by_type(PieceData.Type.SMELTER)
	assert_gt(smelter_recipes.size(), 0, "SMELTER用レシピがあるべき")


func test_TypeでCutterのレシピ一覧を取得できる():
	Recipe.RecipeDB._static_init()
	var recipes = Recipe.RecipeDB.get_recipes_by_type(PieceData.Type.CUTTER)
	assert_gt(recipes.size(), 0, "CUTTER用レシピがあるべき")
	assert_eq(recipes[0].outputs.get("iron_rod", 0), 1, "iron_rod を出力するべき")


func test_TypeでMixerのレシピ一覧を取得できる():
	Recipe.RecipeDB._static_init()
	var recipes = Recipe.RecipeDB.get_recipes_by_type(PieceData.Type.MIXER)
	assert_gt(recipes.size(), 0, "MIXER用レシピがあるべき")
	assert_eq(recipes[0].outputs.get("screw", 0), 1, "screw を出力するべき")


func test_未定義Typeはレシピなしになる():
	Recipe.RecipeDB._static_init()
	var recipes = Recipe.RecipeDB.get_recipes_by_type(PieceData.Type.CONVEYOR)
	assert_eq(recipes.size(), 0, "CONVEYOR用レシピは未定義のため空であるべき")


func test_TypeでMinerのレシピ一覧を取得できる():
	Recipe.RecipeDB._static_init()
	var miner_recipes = Recipe.RecipeDB.get_recipes_by_type(PieceData.Type.MINER)
	assert_gt(miner_recipes.size(), 0, "MINER用レシピがあるべき")


func test_Recipeにはroleフィールドが存在しない():
	var recipe = Recipe.new("test", {}, {"iron_ore": 1}, 1.0)
	assert_false("role" in recipe, "Recipe に role フィールドは不要")


func test_items_per_minuteは60割るcraft_timeを返す():
	var recipe = Recipe.new("test", {}, {"iron_ingot": 1}, 2.0)
	assert_eq(recipe.items_per_minute(), 30.0)


func test_全バイオームの資源に対応する採掘レシピがある():
	for biome_id in Biome.all_ids():
		var resource_type = Biome.get_biome(biome_id).resource_type
		var recipe = Recipe.RecipeDB.get_mining_recipe(resource_type)
		assert_not_null(recipe, resource_type)
		if recipe:
			assert_eq(recipe.outputs, {resource_type: 1})
			assert_eq(recipe.inputs, {})


func test_採掘できない資源の採掘レシピはnull():
	assert_null(Recipe.RecipeDB.get_mining_recipe("iron_plate"))


func test_製錬炉は銅鉱石から銅インゴットを作れる():
	var recipes = Recipe.RecipeDB.get_recipes_by_type(PieceData.Type.SMELTER)
	var found = recipes.filter(
		func(r): return r.inputs == {"copper_ore": 1} and r.outputs == {"copper_ingot": 1}
	)
	assert_eq(found.size(), 1)


func test_ミキサーは鉄インゴットと石炭から鋼材を作れる():
	var recipes = Recipe.RecipeDB.get_recipes_by_type(PieceData.Type.MIXER)
	var found = recipes.filter(
		func(r): return r.inputs == {"iron_ingot": 1, "coal": 1} and r.outputs == {"steel": 1}
	)
	assert_eq(found.size(), 1)


func _has_recipe(piece_type: PieceData.Type, inputs: Dictionary, output: String) -> bool:
	var recipes = Recipe.RecipeDB.get_recipes_by_type(piece_type)
	return recipes.any(func(r): return r.inputs == inputs and r.outputs == {output: 1})


func test_Cutterは銅インゴットから銅線を作れる():
	assert_true(_has_recipe(PieceData.Type.CUTTER, {"copper_ingot": 1}, "copper_wire"))


func test_Assemblerは鋼材から鉄骨を作れる():
	assert_true(_has_recipe(PieceData.Type.ASSEMBLER, {"steel": 1}, "steel_beam"))


func test_Mixerは銅線と鉄板から回路を作れる():
	assert_true(_has_recipe(PieceData.Type.MIXER, {"copper_wire": 1, "iron_plate": 1}, "circuit"))


func test_既存の機械の最初のレシピは変わらない():
	# 設置直後の既定レシピ（情報パネルのスピード表示の基準）を変えない
	assert_eq(Recipe.RecipeDB.get_recipes_by_type(PieceData.Type.CUTTER)[0].id, "iron_rod")
	assert_eq(Recipe.RecipeDB.get_recipes_by_type(PieceData.Type.ASSEMBLER)[0].id, "iron_plate")
	assert_eq(Recipe.RecipeDB.get_recipes_by_type(PieceData.Type.MIXER)[0].id, "screw")


func test_同じ機械のレシピ同士で材料が重ならない():
	# 機械は届いた材料からレシピを選ぶので、材料が重なるとどちらを作るか決まらない
	for piece_type in [
		PieceData.Type.SMELTER,
		PieceData.Type.ASSEMBLER,
		PieceData.Type.CUTTER,
		PieceData.Type.MIXER
	]:
		var seen = {}
		for recipe in Recipe.RecipeDB.get_recipes_by_type(piece_type):
			for item in recipe.inputs:
				assert_false(seen.has(item), "%s が複数のレシピの材料になっている" % item)
				seen[item] = true
