extends GutTest

var crafter: Crafter
var input_container: ItemContainer
var output_container: ItemContainer


func before_each():
	crafter = Crafter.new()
	input_container = ItemContainer.new()
	output_container = ItemContainer.new()
	crafter.setup(input_container, output_container)


func after_each():
	crafter.free()
	input_container.free()
	output_container.free()


func test_レシピを設定し初期化される():
	var recipe = Recipe.new("test", {}, {"out": 1}, 1.0)
	crafter.set_recipe(recipe)

	assert_eq(crafter.current_recipe, recipe)
	assert_eq(crafter.processing_progress, 0.0)


func test_材料が足りていれば開始可能と判定される():
	var recipe = Recipe.new("test", {"ore": 1}, {"ingot": 1}, 1.0)
	crafter.set_recipe(recipe)
	input_container.add_item("ore", 1)

	assert_true(crafter._can_start_crafting(), "材料があれば開始できるべき")


func test_材料が不足していれば開始不可と判定される():
	var recipe = Recipe.new("test", {"ore": 2}, {"ingot": 1}, 1.0)
	crafter.set_recipe(recipe)
	input_container.add_item("ore", 1)

	assert_false(crafter._can_start_crafting(), "材料が足りなければ開始できないべき")


func test_加工開始時に材料が消費される():
	var recipe = Recipe.new("test", {"ore": 1}, {"ingot": 1}, 1.0)
	crafter.set_recipe(recipe)
	input_container.add_item("ore", 1)

	crafter._start_crafting()

	assert_eq(input_container.get_item_count("ore"), 0, "開始時に材料が消費されるべき")
	assert_gt(crafter.processing_progress, 0.0, "開始時に進捗が微増するべき")


func test_tickで加工進捗が進む():
	var recipe = Recipe.new("test", {}, {"out": 1}, 1.0)
	crafter.set_recipe(recipe)
	crafter.start_crafting()

	crafter.tick(0.5)
	assert_almost_eq(crafter.processing_progress, 0.5, 0.01)

	crafter.tick(0.3)
	assert_almost_eq(crafter.processing_progress, 0.8, 0.01)


func test_加工完了時に成果物が生成され進捗がリセットされる():
	var recipe = Recipe.new("test", {}, {"ingot": 1}, 1.0)
	crafter.set_recipe(recipe)
	crafter.processing_progress = 0.9

	crafter.tick(0.2)  # 合計 1.1 で完了

	assert_eq(output_container.get_item_count("ingot"), 1, "完了時に成果物が出るべき")
	assert_eq(crafter.processing_progress, 0.0, "完了時に進捗がリセットされるべき")


func test_レシピがない場合はtickで何もしない():
	crafter.tick(1.0)
	assert_eq(crafter.processing_progress, 0.0)


func test_アウトプットインベントリが満杯の場合は開始不可と判定される():
	var recipe = Recipe.new("test", {"ore": 1}, {"ingot": 1}, 1.0)
	crafter.set_recipe(recipe)
	input_container.add_item("ore", 1)

	# アウトプットインベントリに20個アイテムを入れる
	output_container.add_item("junk", 20)

	assert_false(crafter._can_start_crafting(), "アウトプットインベントリが満杯なら開始できないべき")


func test_アウトプットインベントリが満杯の場合は加工が開始されない():
	var recipe = Recipe.new("test", {"ore": 1}, {"ingot": 1}, 1.0)
	crafter.set_recipe(recipe)
	input_container.add_item("ore", 1)
	output_container.add_item("junk", 20)

	crafter.tick(0.1)

	assert_eq(crafter.processing_progress, 0.0, "満杯時はtickを呼んでも進捗が0のままであるべき")
	assert_eq(input_container.get_item_count("ore"), 1, "材料も消費されないべき")
