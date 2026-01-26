# gdlint:disable=function-name
class_name TestRecipe
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
