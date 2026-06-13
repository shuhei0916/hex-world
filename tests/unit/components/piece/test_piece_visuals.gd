extends GutTest

const CONVEYOR_SCENE = preload("res://scenes/components/piece/conveyor.tscn")
const CHEST_SCENE = preload("res://scenes/components/piece/chest.tscn")

var piece_scene = load("res://scenes/components/piece/smelter.tscn")
var piece: Piece


func before_each():
	piece = piece_scene.instantiate()
	add_child_autofree(piece)


func test_アイテムを追加するとInputのIconが表示される():
	piece.add_item("iron_ore", 1)
	assert_true(piece.get_node("Input/Inventory/Icon").visible)


func test_レシピをセットするとSpeedLabelが表示される():
	var recipe = Recipe.new("test", {"iron_ore": 1}, {"iron_ingot": 1}, 2.0)
	piece.set_recipe(recipe)
	assert_true(piece.get_node("SpeedLabel").visible)


func test_レシピをセットするとSpeedLabelに生産速度が表示される():
	var recipe = Recipe.new("test", {"iron_ore": 1}, {"iron_ingot": 1}, 2.0)
	piece.set_recipe(recipe)
	assert_true(piece.get_node("SpeedLabel").text.contains("/m"))


func test_レシピなしはSpeedLabelが非表示():
	assert_false(piece.get_node("SpeedLabel").visible)


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
	assert_not_null(conveyor.get_node("ConveyorVisuals")._line)


func test_rotate_cw後にLine2Dの出力エッジ点が更新される():
	var conveyor = CONVEYOR_SCENE.instantiate()
	add_child_autofree(conveyor)
	conveyor.setup(0)
	var out_before = conveyor.get_node("ConveyorVisuals")._line.get_point_position(2)
	conveyor.rotate_cw()
	var out_after = conveyor.get_node("ConveyorVisuals")._line.get_point_position(2)
	assert_ne(out_after, out_before)


func test_CONVEYORのLine2Dの出力エッジ点が出力方向にある():
	# direction=0 (East): 出力エッジ点は正のX方向にあるはず
	var conveyor = CONVEYOR_SCENE.instantiate()
	add_child_autofree(conveyor)
	conveyor.setup(0)
	var out_edge = conveyor.get_node("ConveyorVisuals")._line.get_point_position(2)
	assert_gt(out_edge.x, 0.0)


func test_CONVEYORのLine2Dは3点を持つ():
	var conveyor = CONVEYOR_SCENE.instantiate()
	add_child_autofree(conveyor)
	conveyor.setup(0)
	assert_eq(conveyor.get_node("ConveyorVisuals")._line.get_point_count(), 3)


func test_SMELTERをsetupしてもLine2Dは追加されない():
	piece.setup(0)
	assert_null(piece.get_node_or_null("ConveyorVisuals"))


func test_CONVEYORをsetupすると出力方向矢印が追加される():
	var conveyor = CONVEYOR_SCENE.instantiate()
	add_child_autofree(conveyor)
	conveyor.setup(0)
	assert_not_null(conveyor._output_arrow, "CONVEYORにも出力方向矢印が表示されるべき")


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
	assert_false(piece.get_node("Output/Inventory/Icon").visible, "出力アイコンは入力がない限り非表示")
