extends GutTest

var piece_scene = load("res://scenes/components/piece/piece.tscn")
var piece: Piece


func before_each():
	piece = piece_scene.instantiate()
	add_child_autofree(piece)


func test_アイテムを追加するとIconが表示される():
	piece.add_item("iron_ore", 1)

	var input_node = piece.get_node_or_null("Input")
	if input_node:
		var icon = input_node.get_node_or_null("Inventory/Icon")
		if icon:
			assert_true(icon.visible, "InputIcon should be visible when item added")


func test_レシピをセットするとSpeedLabelが表示される():
	var recipe = Recipe.new("test", {"iron_ore": 1}, {"iron_ingot": 1}, 2.0)
	piece.set_recipe(recipe)

	var speed_label = piece.get_node_or_null("SpeedLabel")
	if speed_label:
		assert_true(speed_label.visible, "SpeedLabel should be visible when recipe is set")
		assert_true(speed_label.text.contains("/m"), "Speed text should contain /m")


func test_レシピなしはSpeedLabelが非表示():
	var speed_label = piece.get_node_or_null("SpeedLabel")
	if speed_label:
		assert_false(speed_label.visible, "SpeedLabel should be hidden with no recipe")


func test_レシピをセットしても出力Iconは表示されない():
	var recipe = Recipe.new("test", {"iron_ore": 1}, {"iron_ingot": 1}, 2.0)
	piece.setup(PieceData.get_data(PieceData.Type.SMELTER))
	piece.set_recipe(recipe)
	var icon = piece.get_node_or_null("Output/Inventory/Icon")
	if icon:
		assert_false(icon.visible, "出力アイコンは入力がない限り非表示")
