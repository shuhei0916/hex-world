extends GutTest

const CONVEYOR_SCENE = preload("res://scenes/components/piece/conveyor.tscn")
const CHEST_SCENE = preload("res://scenes/components/piece/chest.tscn")

var piece_scene = load("res://scenes/components/piece/smelter.tscn")
var piece: Piece


func before_each():
	piece = piece_scene.instantiate()
	add_child_autofree(piece)


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


func test_ベルトのフレームindexは経過時間で進み14コマで循環する():
	# 14コマ分(0.70s)離れた時刻は同じフレームを指すべき（循環）
	assert_eq(ConveyorVisuals.frame_for_time(0.76), ConveyorVisuals.frame_for_time(0.06))


func test_forwardベルトフレームは14枚ある():
	assert_eq(ConveyorVisuals.BELT_FRAMES.size(), 14)


func test_CONVEYORをsetupするとベルトのLine2Dが追加される():
	var conveyor = CONVEYOR_SCENE.instantiate()
	add_child_autofree(conveyor)
	conveyor.setup(0)
	assert_not_null(conveyor.get_node("ConveyorVisuals")._belt)


func test_rotate_cw後に出力エッジ点が更新される():
	var conveyor = CONVEYOR_SCENE.instantiate()
	add_child_autofree(conveyor)
	conveyor.setup(0)
	var out_before = conveyor.get_node("ConveyorVisuals")._path[2]
	conveyor.rotate_cw()
	var out_after = conveyor.get_node("ConveyorVisuals")._path[2]
	assert_ne(out_after, out_before)


func test_CONVEYORの出力エッジ点が出力方向にある():
	# direction=0 (East): 出力エッジ点は正のX方向にあるはず
	var conveyor = CONVEYOR_SCENE.instantiate()
	add_child_autofree(conveyor)
	conveyor.setup(0)
	var out_edge = conveyor.get_node("ConveyorVisuals")._path[2]
	assert_gt(out_edge.x, 0.0)


func test_CONVEYORのベルトパスは3点を持つ():
	var conveyor = CONVEYOR_SCENE.instantiate()
	add_child_autofree(conveyor)
	conveyor.setup(0)
	assert_eq(conveyor.get_node("ConveyorVisuals")._path.size(), 3)


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


func test_コンベア上のアイテムはコンベアのラインより手前に描画される():
	var conveyor = CONVEYOR_SCENE.instantiate()
	add_child_autofree(conveyor)
	conveyor.setup(0)
	var visuals = conveyor.get_node("ConveyorVisuals")
	var item_icon = visuals.get_node("ItemIcon")
	assert_lt(visuals._belt.z_index, item_icon.z_index)


func test_コンベア上のアイテムは絶対zで描画され施設タイルに依存しない():
	var conveyor = CONVEYOR_SCENE.instantiate()
	add_child_autofree(conveyor)
	conveyor.setup(0)
	var item_icon = conveyor.get_node("ConveyorVisuals/ItemIcon")
	assert_false(item_icon.z_as_relative)


func test_レシピをセットしても出力Iconは表示されない():
	var recipe = Recipe.new("test", {"iron_ore": 1}, {"iron_ingot": 1}, 2.0)
	piece.setup()
	piece.set_recipe(recipe)
	assert_false(piece.get_node("Output/Inventory/Icon").visible, "出力アイコンは入力がない限り非表示")


func test_コンベアの土台タイルは機械の施設タイルより奥に描画される():
	var conveyor = CONVEYOR_SCENE.instantiate()
	add_child_autofree(conveyor)
	conveyor.setup(0)
	piece.setup(0)
	assert_lt(_first_hextile(conveyor).z_index, _first_hextile(piece).z_index)


func _first_hextile(p) -> HexTile:
	for child in p.get_children():
		if child is HexTile:
			return child
	return null
