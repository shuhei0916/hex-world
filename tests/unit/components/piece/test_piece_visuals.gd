extends GutTest

const CONVEYOR_SCENE = preload("res://scenes/components/piece/conveyor.tscn")
const CHEST_SCENE = preload("res://scenes/components/piece/chest.tscn")

var piece_scene = load("res://scenes/components/piece/smelter.tscn")
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


func test_make_output_arrowがSprite2Dを返す():
	var port = {"hex": Hex.new(0, 0, 0), "direction": 0}
	var arrow = Piece.make_output_arrow(port)
	assert_is(arrow, Sprite2D)
	arrow.free()


func test_make_output_arrowのrotationが進行方向の角度になる():
	# direction=0 (East): 隣接ヘックスはEast方向 → angle=0
	var port = {"hex": Hex.new(0, 0, 0), "direction": 0}
	var arrow = Piece.make_output_arrow(port)
	var layout = Layout.make_default()
	var center_pos = Layout.hex_to_pixel(layout, port["hex"])
	var neighbor_pos = Layout.hex_to_pixel(layout, Hex.neighbor(port["hex"], 0))
	var expected_angle = (neighbor_pos - center_pos).angle()
	assert_almost_eq(arrow.rotation, expected_angle, 0.001)
	arrow.free()


func test_make_output_arrowのpositionがPORT_OFFSETの距離になる():
	var port = {"hex": Hex.new(0, 0, 0), "direction": 0}
	var arrow = Piece.make_output_arrow(port)
	var layout = Layout.make_default()
	var center_pos = Layout.hex_to_pixel(layout, port["hex"])
	var dist = arrow.position.distance_to(center_pos)
	assert_almost_eq(dist, Piece.PORT_OFFSET, 0.01)
	arrow.free()


func test_CONVEYORをsetupするとLine2Dの子ノードが追加される():
	var conveyor = CONVEYOR_SCENE.instantiate()
	add_child_autofree(conveyor)
	conveyor.setup(0)
	var lines = conveyor.get_children().filter(func(c): return c is Line2D)
	assert_eq(lines.size(), 1)


func test_CONVEYORのLine2Dの出力エッジ点が出力方向にある():
	# direction=0 (East): 出力エッジ点は正のX方向にあるはず
	var conveyor = CONVEYOR_SCENE.instantiate()
	add_child_autofree(conveyor)
	conveyor.setup(0)
	var line = conveyor.get_children().filter(func(c): return c is Line2D)[0] as Line2D
	var out_edge = line.get_point_position(2)
	assert_gt(out_edge.x, 0.0)


func test_CONVEYORのLine2Dは3点を持つ():
	var conveyor = CONVEYOR_SCENE.instantiate()
	add_child_autofree(conveyor)
	conveyor.setup(0)
	var line = conveyor.get_children().filter(func(c): return c is Line2D)[0] as Line2D
	assert_eq(line.get_point_count(), 3)


func test_CONVEYORをsetupするとOutputPortノードではなくSprite2Dで矢印が追加される():
	var conveyor = CONVEYOR_SCENE.instantiate()
	add_child_autofree(conveyor)
	conveyor.setup(0)
	assert_null(conveyor.get_node_or_null("OutputPort"), "OutputPortノードは存在しないはず")


func test_rotate_cw後に矢印のrotationが更新される():
	var conveyor = CONVEYOR_SCENE.instantiate()
	add_child_autofree(conveyor)
	conveyor.setup(0)
	var rotation_before = conveyor._output_arrow.rotation
	conveyor.rotate_cw()
	assert_ne(conveyor._output_arrow.rotation, rotation_before)


func test_CHESTをsetupしても矢印の子ノードは追加されない():
	var chest = CHEST_SCENE.instantiate()
	add_child_autofree(chest)
	chest.setup(0)
	var arrows = chest.get_children().filter(
		func(c): return c is Sprite2D and c.texture == Piece.FORWARD_TEXTURE
	)
	assert_eq(arrows.size(), 0)


func test_レシピをセットしても出力Iconは表示されない():
	var recipe = Recipe.new("test", {"iron_ore": 1}, {"iron_ingot": 1}, 2.0)
	piece.setup()
	piece.set_recipe(recipe)
	var icon = piece.get_node_or_null("Output/Inventory/Icon")
	if icon:
		assert_false(icon.visible, "出力アイコンは入力がない限り非表示")
