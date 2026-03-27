# gdlint:disable=function-name

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
