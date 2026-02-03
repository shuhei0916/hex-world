extends GutTest

var Crafter = load("res://scenes/components/piece/crafter.gd")
var ItemContainer = load("res://scenes/components/piece/item_container.gd")

var crafter
var input_container
var output_container


func before_each():
	if Crafter:
		crafter = Crafter.new()
	if ItemContainer:
		input_container = ItemContainer.new()
		output_container = ItemContainer.new()


func after_each():
	if crafter:
		crafter.free()
	if input_container:
		input_container.free()
	if output_container:
		output_container.free()


func test_レシピを設定し進捗を管理できる():
	if not crafter:
		return

	var recipe = Recipe.new("test", {}, {"out": 1}, 1.0)
	crafter.set_recipe(recipe)

	assert_eq(crafter.current_recipe, recipe, "レシピが保持されるべき")
	assert_eq(crafter.processing_progress, 0.0, "初期進捗は0であるべき")


func test_加工進捗が時間経過で進む():
	if not crafter:
		return

	var recipe = Recipe.new("test", {}, {"out": 1}, 1.0)
	crafter.set_recipe(recipe)

	crafter.start_crafting()
	crafter.tick(0.5)

	assert_gt(crafter.processing_progress, 0.0, "加工が開始され進捗が進むべき")


func test_材料がある場合に自動で加工を開始し完了時に成果物を生成する():
	if not crafter or not input_container:
		return

	# セットアップ
	crafter.setup(input_container, output_container)

	# レシピ: ore 1 -> ingot 1 (時間 1.0)
	var recipe = Recipe.new("smelt", {"ore": 1}, {"ingot": 1}, 1.0)
	crafter.set_recipe(recipe)

	# 材料投入
	input_container.add_item("ore", 1)

	# 1. 加工開始判定 & 開始 (消費)
	# tick内で can_start -> start (consume) -> progress=0.001 になるはず
	crafter.tick(0.1)

	assert_gt(crafter.processing_progress, 0.0, "加工が開始されるべき")
	assert_eq(input_container.get_item_count("ore"), 0, "材料が消費されるべき")

	# 2. 加工完了
	crafter.tick(1.0)  # 時間経過

	assert_eq(crafter.processing_progress, 0.0, "完了したら進捗リセット")
	assert_eq(output_container.get_item_count("ingot"), 1, "成果物が生成されるべき")
