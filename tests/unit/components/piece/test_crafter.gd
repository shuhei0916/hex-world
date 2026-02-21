# gdlint:disable=constant-name
extends GutTest

const PIECE_SCENE = preload("res://scenes/components/piece/piece.tscn")
const PieceInputScript = preload("res://scenes/components/piece/input.gd")
const OutputScript = preload("res://scenes/components/piece/output.gd")


class TestCrafterLogic:
	extends GutTest

	var crafter: Crafter
	var input_container
	var output_container

	func before_each():
		crafter = Crafter.new()
		input_container = PieceInputScript.new()
		output_container = OutputScript.new()
		crafter.setup(input_container, output_container)

	func after_each():
		crafter.free()
		input_container.free()
		output_container.free()

	func test_レシピを設定し初期化される():
		var recipe = Recipe.new("test", {}, {"out": 1}, 1.0)
		crafter.set_recipe(recipe)
		assert_eq(crafter.current_recipe, recipe)

	func test_設定後の進捗はゼロである():
		var recipe = Recipe.new("test", {}, {"out": 1}, 1.0)
		crafter.set_recipe(recipe)
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

	func test_加工開始時に進捗が微増する():
		var recipe = Recipe.new("test", {"ore": 1}, {"ingot": 1}, 1.0)
		crafter.set_recipe(recipe)
		input_container.add_item("ore", 1)
		crafter._start_crafting()
		assert_gt(crafter.processing_progress, 0.0, "開始時に進捗が微増するべき")

	func test_tickで加工進捗が進む():
		var recipe = Recipe.new("test", {}, {"out": 1}, 1.0)
		crafter.set_recipe(recipe)
		crafter.start_crafting()
		crafter.tick(0.5)
		assert_almost_eq(crafter.processing_progress, 0.5, 0.01)

	func test_加工完了時に成果物が生成される():
		var recipe = Recipe.new("test", {}, {"ingot": 1}, 1.0)
		crafter.set_recipe(recipe)
		crafter.processing_progress = 0.9
		crafter.tick(0.2)
		assert_eq(output_container.get_item_count("ingot"), 1, "完了時に成果物が出るべき")

	func test_加工完了時に進捗がリセットされる():
		var recipe = Recipe.new("test", {}, {"ingot": 1}, 1.0)
		crafter.set_recipe(recipe)
		crafter.processing_progress = 0.9
		crafter.tick(0.2)
		assert_eq(crafter.processing_progress, 0.0, "完了時に進捗がリセットされるべき")

	func test_レシピがない場合はtickで何もしない():
		crafter.tick(1.0)
		assert_eq(crafter.processing_progress, 0.0)

	func test_アウトプットが満杯の場合は開始不可と判定される():
		var recipe = Recipe.new("test", {"ore": 1}, {"ingot": 1}, 1.0)
		crafter.set_recipe(recipe)
		input_container.add_item("ore", 1)
		output_container.add_item("junk", 20)
		assert_false(crafter._can_start_crafting(), "アウトプットが満杯なら開始できないべき")

	func test_アウトプットが満杯の場合は加工が開始されない():
		var recipe = Recipe.new("test", {"ore": 1}, {"ingot": 1}, 1.0)
		crafter.set_recipe(recipe)
		input_container.add_item("ore", 1)
		output_container.add_item("junk", 20)
		crafter.tick(0.1)
		assert_eq(crafter.processing_progress, 0.0, "満杯時はtickを呼んでも進捗が0のままであるべき")


class TestCrafterProgressBar:
	extends GutTest

	var piece: Piece
	var crafter: Crafter
	var progress_bar: ProgressBar

	func before_each():
		piece = PIECE_SCENE.instantiate()
		add_child(piece)
		autofree(piece)
		crafter = piece.get_node("Crafter")
		progress_bar = crafter.get_node_or_null("ProgressBar")

	func test_加工中はProgressBarが表示される():
		if not progress_bar:
			return
		var recipe = Recipe.new("test", {}, {"out": 1}, 1.0)
		piece.set_recipe(recipe)
		piece.tick(0.01)
		assert_true(progress_bar.visible, "加工中は ProgressBar が表示されるべき")

	func test_レシピがない場合はProgressBarが非表示():
		if not progress_bar:
			return
		assert_false(progress_bar.visible, "レシピなしは ProgressBar が非表示であるべき")
