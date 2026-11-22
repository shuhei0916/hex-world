extends GutTest

# docs/recipe_plan.md のレシピ表。[機械, 材料, 出力, 秒]
const RECIPE_TABLE = [
	[PieceData.Type.SMELTER, {"iron_ore": 1}, {"iron_ingot": 1}, 2.0],
	[PieceData.Type.SMELTER, {"copper_ore": 1}, {"copper_ingot": 1}, 2.0],
	[PieceData.Type.SMELTER, {"sand": 2}, {"glass": 1}, 3.0],
	[PieceData.Type.CUTTER, {"iron_ingot": 1}, {"iron_plate": 1}, 3.0],
	[PieceData.Type.CUTTER, {"iron_plate": 1}, {"screw": 2}, 3.0],
	[PieceData.Type.CUTTER, {"copper_ingot": 1}, {"copper_wire": 2}, 3.0],
	[PieceData.Type.CUTTER, {"steel": 1}, {"steel_beam": 1}, 4.0],
	[PieceData.Type.CUTTER, {"glass": 1}, {"lens": 1}, 4.0],
	[PieceData.Type.MIXER, {"iron_ingot": 1, "coal": 1}, {"steel": 1}, 4.0],
	[PieceData.Type.MIXER, {"copper_wire": 2, "iron_plate": 1}, {"circuit": 1}, 6.0],
	[PieceData.Type.MIXER, {"steel_beam": 2, "screw": 2}, {"frame": 1}, 6.0],
	[PieceData.Type.MIXER, {"lens": 1, "circuit": 1}, {"sensor": 1}, 8.0],
	[PieceData.Type.MIXER, {"quicklime": 1, "sand": 2}, {"concrete": 1}, 4.0],
	[PieceData.Type.KILN, {"limestone": 1}, {"quicklime": 1}, 3.0],
	[PieceData.Type.ASSEMBLER, {"iron_plate": 1, "screw": 2}, {"gear": 1}, 4.0],
	[PieceData.Type.ASSEMBLER, {"gear": 1, "copper_wire": 2}, {"motor": 1}, 6.0],
	[PieceData.Type.ASSEMBLER, {"frame": 1, "motor": 1}, {"engine": 1}, 8.0],
	[PieceData.Type.ASSEMBLER, {"sensor": 1, "engine": 1}, {"probe": 1}, 12.0],
]


func test_レシピデータを初期化できる():
	var recipe = Recipe.new("iron_ingot_smelting", {"iron_ore": 1}, {"iron_ingot": 1}, 2.0)

	assert_eq(recipe.id, "iron_ingot_smelting")
	assert_eq(recipe.inputs["iron_ore"], 1)
	assert_eq(recipe.outputs["iron_ingot"], 1)
	assert_eq(recipe.craft_time, 2.0)


func test_品目を作るレシピを引ける():
	var recipes = Recipe.RecipeDB.get_recipes_producing("iron_ingot")
	assert_eq(recipes.size(), 1)
	assert_eq(recipes[0].inputs, {"iron_ore": 1})


func test_作るレシピの無い品目では空():
	assert_eq(Recipe.RecipeDB.get_recipes_producing("no_such_item"), [])


func test_採掘で手に入る資源も採掘機のレシピとして引ける():
	var recipes = Recipe.RecipeDB.get_recipes_producing("coal")
	assert_eq(recipes.size(), 1)
	assert_eq(recipes[0].inputs, {})


func test_TypeでSmelterのレシピ一覧を取得できる():
	Recipe.RecipeDB._static_init()
	var smelter_recipes = Recipe.RecipeDB.get_recipes_by_type(PieceData.Type.SMELTER)
	assert_gt(smelter_recipes.size(), 0, "SMELTER用レシピがあるべき")


func test_TypeでCutterのレシピ一覧を取得できる():
	Recipe.RecipeDB._static_init()
	var recipes = Recipe.RecipeDB.get_recipes_by_type(PieceData.Type.CUTTER)
	assert_gt(recipes.size(), 0, "CUTTER用レシピがあるべき")
	assert_eq(recipes[0].outputs.get("iron_plate", 0), 1, "iron_plate を出力するべき")


func test_TypeでMixerのレシピ一覧を取得できる():
	Recipe.RecipeDB._static_init()
	var recipes = Recipe.RecipeDB.get_recipes_by_type(PieceData.Type.MIXER)
	assert_gt(recipes.size(), 0, "MIXER用レシピがあるべき")
	assert_eq(recipes[0].outputs.get("steel", 0), 1, "steel を出力するべき")


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


func test_レシピ表のとおりのレシピがある():
	for row in RECIPE_TABLE:
		var found = Recipe.RecipeDB.get_recipes_by_type(row[0]).filter(
			func(r): return r.inputs == row[1] and r.outputs == row[2]
		)
		assert_eq(found.size(), 1, "%s → %s" % [row[1], row[2]])
		if found.size() == 1:
			assert_eq(found[0].craft_time, row[3], "%s の時間" % row[2])


func test_加工機のレシピはレシピ表にあるものだけ():
	for piece_type in [
		PieceData.Type.SMELTER,
		PieceData.Type.CUTTER,
		PieceData.Type.MIXER,
		PieceData.Type.ASSEMBLER,
		PieceData.Type.KILN,
	]:
		var expected = RECIPE_TABLE.filter(func(row): return row[0] == piece_type).size()
		assert_eq(Recipe.RecipeDB.get_recipes_by_type(piece_type).size(), expected)


func test_材料は2種類まで_個数は2個まで_出力は1種類():
	for row in RECIPE_TABLE:
		assert_lte(row[1].size(), 2)
		for count in row[1].values():
			assert_lte(count, 2)
		assert_eq(row[2].size(), 1)


func test_最終目標の探査機は本筋のバイオームの資源をすべて使う():
	# 石灰岩の台地の石灰石は建物の材料（コンクリート）に使い、探査機には使わない
	var raw = _raw_materials("probe")
	for biome_id in [Biome.PLAINS, Biome.MOUNTAINS, Biome.FOREST, Biome.DESERT]:
		var resource_type = Biome.get_biome(biome_id).resource_type
		assert_true(raw.has(resource_type), "%s が要る" % resource_type)


# アイテムを作るのに必要な原料（採掘する資源）を、レシピ表をさかのぼって集める
func _raw_materials(item: String) -> Dictionary:
	for row in RECIPE_TABLE:
		if row[2].has(item):
			var raw = {}
			for input in row[1]:
				raw.merge(_raw_materials(input))
			return raw
	return {item: true}


func test_機械の最初のレシピは段階のいちばん低いもの():
	assert_eq(Recipe.RecipeDB.get_recipes_by_type(PieceData.Type.SMELTER)[0].id, "iron_ingot")
	assert_eq(Recipe.RecipeDB.get_recipes_by_type(PieceData.Type.CUTTER)[0].id, "iron_plate")
	assert_eq(Recipe.RecipeDB.get_recipes_by_type(PieceData.Type.ASSEMBLER)[0].id, "gear")
	assert_eq(Recipe.RecipeDB.get_recipes_by_type(PieceData.Type.MIXER)[0].id, "steel")


func test_同じ機械のレシピ同士で材料が重ならない():
	# 機械は届いた材料からレシピを選ぶので、材料が重なるとどちらを作るか決まらない
	for piece_type in [
		PieceData.Type.SMELTER,
		PieceData.Type.ASSEMBLER,
		PieceData.Type.CUTTER,
		PieceData.Type.MIXER,
		PieceData.Type.KILN,
	]:
		var seen = {}
		for recipe in Recipe.RecipeDB.get_recipes_by_type(piece_type):
			for item in recipe.inputs:
				assert_false(seen.has(item), "%s が複数のレシピの材料になっている" % item)
				seen[item] = true
