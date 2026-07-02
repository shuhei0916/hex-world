# gdlint:disable=constant-name
extends GutTest

const PIECE_SCENE = preload("res://scenes/components/piece/smelter_t2.tscn")


class TestCrafterLogic:
	extends GutTest

	var crafter: Crafter
	var output_container

	func before_each():
		crafter = Crafter.new()
		# 本番と同じく出力先は ItemEjector（容量・満杯判定・add_item を備える）
		output_container = ItemEjector.new()
		crafter.setup(output_container)

	func after_each():
		crafter.free()
		output_container.free()

	func test_レシピを設定し初期化される():
		var recipe = Recipe.new("test", {}, {"out": 1}, 1.0)
		crafter.set_recipe(recipe)
		assert_eq(crafter.current_recipe, recipe)

	func test_設定後の進捗はゼロである():
		var recipe = Recipe.new("test", {}, {"out": 1}, 1.0)
		crafter.set_recipe(recipe)
		assert_eq(crafter.processing_progress, 0.0)

	func test_set_recipeで出力容量がレシピ出力量の合計になる():
		var recipe = Recipe.new("test", {"ore": 1}, {"ingot": 1}, 1.0)
		crafter.set_recipe(recipe)
		assert_eq(output_container.capacity, 1)

	func test_set_recipeで入力容量がレシピ入力量の合計になる():
		var recipe = Recipe.new("test", {"ore": 2}, {"ingot": 1}, 1.0)
		crafter.set_recipe(recipe)
		assert_eq(crafter.input_capacity, 2)

	func test_材料が足りていれば開始可能と判定される():
		var recipe = Recipe.new("test", {"ore": 1}, {"ingot": 1}, 1.0)
		crafter.set_recipe(recipe)
		crafter.add_item("ore", 1)
		assert_true(crafter._can_start_crafting(), "材料があれば開始できるべき")

	func test_材料が不足していれば開始不可と判定される():
		var recipe = Recipe.new("test", {"ore": 2}, {"ingot": 1}, 1.0)
		crafter.set_recipe(recipe)
		crafter.add_item("ore", 1)
		assert_false(crafter._can_start_crafting(), "材料が足りなければ開始できないべき")

	func test_加工開始時に材料が消費される():
		var recipe = Recipe.new("test", {"ore": 1}, {"ingot": 1}, 1.0)
		crafter.set_recipe(recipe)
		crafter.add_item("ore", 1)
		crafter._start_crafting()
		assert_eq(crafter.get_item_count("ore"), 0, "開始時に材料が消費されるべき")

	func test_加工開始時に進捗が微増する():
		var recipe = Recipe.new("test", {"ore": 1}, {"ingot": 1}, 1.0)
		crafter.set_recipe(recipe)
		crafter.add_item("ore", 1)
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

	func test_output_multiplier_3でも完成個数はレシピ通り1個():
		var recipe = Recipe.new("test", {}, {"ingot": 1}, 1.0)
		crafter.set_recipe(recipe)
		crafter.output_multiplier = 3
		crafter.start_crafting()
		crafter.tick(0.4)  # 実効加工時間 1.0/3≈0.33 を超える
		assert_eq(output_container.get_item_count("ingot"), 1)

	func test_output_multiplier_3のとき実効加工時間3分の1で完成する():
		var recipe = Recipe.new("test", {}, {"ingot": 1}, 1.0)
		crafter.set_recipe(recipe)
		crafter.output_multiplier = 3
		crafter.start_crafting()
		crafter.tick(0.34)  # 通常の1.0未満だが 1.0/3≈0.333 は超えるので完成するはず
		assert_eq(crafter.processing_progress, 0.0, "実効時間を超えたら完成し進捗がリセットされる")

	func test_アウトプットが満杯の場合は開始不可と判定される():
		var recipe = Recipe.new("test", {"ore": 1}, {"ingot": 1}, 1.0)
		crafter.set_recipe(recipe)
		crafter.add_item("ore", 1)
		output_container.add_item("junk", 1)  # 出力容量はレシピ1回分(1)なので1個で満杯
		assert_false(crafter._can_start_crafting(), "アウトプットが満杯なら開始できないべき")

	func test_アウトプットが満杯の場合は加工が開始されない():
		var recipe = Recipe.new("test", {"ore": 1}, {"ingot": 1}, 1.0)
		crafter.set_recipe(recipe)
		crafter.add_item("ore", 1)
		output_container.add_item("junk", 1)  # 出力容量はレシピ1回分(1)なので1個で満杯
		crafter.tick(0.1)
		assert_eq(crafter.processing_progress, 0.0, "満杯時はtickを呼んでも進捗が0のままであるべき")


class TestCrafterMultiInput:
	extends GutTest

	var crafter: Crafter
	var output_container

	func before_each():
		crafter = Crafter.new()
		output_container = ItemEjector.new()
		crafter.setup(output_container)

	func after_each():
		crafter.free()
		output_container.free()

	func test_異なる種別のアイテムを複数スロットで保持できる():
		var recipe = Recipe.new("test", {"ore": 1, "coal": 1}, {"ingot": 1}, 2.0)
		crafter.set_recipe(recipe)
		crafter.add_item("ore", 1)
		crafter.add_item("coal", 1)
		assert_eq(crafter.get_item_count("ore"), 1, "ore が保持されているべき")
		assert_eq(crafter.get_item_count("coal"), 1, "coal が保持されているべき")

	func test_複数種別の材料が揃えば加工開始できる():
		var recipe = Recipe.new("test", {"ore": 1, "coal": 1}, {"ingot": 1}, 2.0)
		crafter.set_recipe(recipe)
		crafter.add_item("ore", 1)
		crafter.add_item("coal", 1)
		assert_true(crafter._can_start_crafting(), "複数材料が揃えば開始できるべき")

	func test_複数種別の材料は加工開始時に全て消費される():
		var recipe = Recipe.new("test", {"ore": 1, "coal": 1}, {"ingot": 1}, 2.0)
		crafter.set_recipe(recipe)
		crafter.add_item("ore", 1)
		crafter.add_item("coal", 1)
		crafter._start_crafting()
		assert_eq(crafter.get_item_count("ore"), 0, "開始時に ore が消費されるべき")
		assert_eq(crafter.get_item_count("coal"), 0, "開始時に coal が消費されるべき")


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

	func test_加工開始直後_完了前は出力Iconが表示されない():
		var recipe = Recipe.new("test", {}, {"iron_ore": 1}, 1.0)
		piece.set_recipe(recipe)
		piece.tick(0.01)  # craft_time=1.0 なのでまだ完了していない
		var visual = piece.get_node("ItemEjectorVisual")
		visual.update_item_icon()
		assert_false(visual.get_node("ItemIcon").visible, "生産完了前は出力Iconを表示しないべき")

	func test_加工完了後は出力Iconが表示される():
		var recipe = Recipe.new("test", {}, {"iron_ore": 1}, 1.0)
		piece.set_recipe(recipe)
		piece.tick(1.1)  # 完了させる
		var visual = piece.get_node("ItemEjectorVisual")
		visual.update_item_icon()
		assert_true(visual.get_node("ItemIcon").visible, "生産完了後は出力Iconが表示されるべき")
