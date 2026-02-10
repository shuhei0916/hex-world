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


func test_指定した施設タイプのレシピ一覧を取得できる():
	Recipe.RecipeDB._static_init()

	# Miner (iron_ore)
	var miner_recipes = Recipe.RecipeDB.get_recipes_by_facility("miner")
	assert_gt(miner_recipes.size(), 0, "Miner用レシピがあるべき")
	assert_eq(miner_recipes[0].facility_type, "miner")

	# Smelter (iron_ingot)
	var smelter_recipes = Recipe.RecipeDB.get_recipes_by_facility("smelter")
	assert_gt(smelter_recipes.size(), 0, "Smelter用レシピがあるべき")
	assert_eq(smelter_recipes[0].facility_type, "smelter")

	# Unknown
	var unknown_recipes = Recipe.RecipeDB.get_recipes_by_facility("unknown_facility")
	assert_eq(unknown_recipes.size(), 0, "不明な施設タイプのレシピは空であるべき")
