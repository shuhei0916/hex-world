extends GutTest

const CONVEYOR_SCENE = preload("res://scenes/components/piece/conveyor.tscn")

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


func test_ベルトのパスは非空():
	var conveyor = CONVEYOR_SCENE.instantiate()
	add_child_autofree(conveyor)
	conveyor.setup(0)
	assert_gt(conveyor.get_node("ConveyorVisuals")._path.size(), 0)


func test_CONVEYORをsetupするとパスが構築される():
	var conveyor = CONVEYOR_SCENE.instantiate()
	add_child_autofree(conveyor)
	conveyor.setup(0)
	assert_gt(conveyor.get_node("ConveyorVisuals")._path.size(), 0)


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


func test_CONVEYORは出力方向矢印を表示しない():
	# ベルト画像自体が方向を示すため、コンベアには矢印を出さない。
	var conveyor = CONVEYOR_SCENE.instantiate()
	add_child_autofree(conveyor)
	conveyor.setup(0)
	assert_null(conveyor._output_arrow, "コンベアは矢印を表示しないべき")


func test_コンベア上のアイテムはコンベアのラインより手前に描画される():
	var conveyor = CONVEYOR_SCENE.instantiate()
	add_child_autofree(conveyor)
	conveyor.setup(0)
	var visuals = conveyor.get_node("ConveyorVisuals")
	var item_icon = visuals.get_node("ItemIcon")
	assert_lt(visuals.z_index, item_icon.z_index)


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
	var visual = piece.get_node("ItemEjectorVisual")
	visual.update_item_icon()
	assert_false(visual.get_node("ItemIcon").visible, "出力アイコンは入力がない限り非表示")


func test_コンベアは基礎タイルを持たない():
	# ベルト画像自体が見た目を担うため、コンベアは色付き基礎タイルを描かない。
	var conveyor = CONVEYOR_SCENE.instantiate()
	add_child_autofree(conveyor)
	conveyor.setup(0)
	var tile_count = 0
	for child in conveyor.get_children():
		if child is HexTile:
			tile_count += 1
	assert_eq(tile_count, 0)


func test_分岐コンベアでアイテムが2番目の出力方向に向かうときアイコンはそのパス上を進む():
	# A: East(dir=0) と NE(dir=1) に分岐。1個目はEastへ排出済み、2個目はNEへ向かう
	var gm = load("res://scenes/components/chunk/chunk.gd").new()
	add_child_autofree(gm)
	gm.create_hex_grid(3)
	gm.place_piece(CONVEYOR_SCENE, Hex.new(0, 0))  # A
	gm.place_piece(CONVEYOR_SCENE, Hex.new(1, 0))  # B: East（1番目の出力先）
	gm.place_piece(CONVEYOR_SCENE, Hex.new(1, -1), 5)  # C: NE（2番目の出力先）
	var a = gm.get_piece_at_hex(Hex.new(0, 0))
	var logic = a.get_node("ConveyorLogic")
	var visuals = a.get_node("ConveyorVisuals")
	# 1個目を排出して round-robin を NE 側へ進める
	a.add_item("iron_ore", 1)
	logic.tick(TransferBuffer.TRANSFER_TIME)
	# 2個目は NE 方向へ向かう
	a.add_item("iron_ore", 1)
	logic.tick(TransferBuffer.TRANSFER_TIME * 0.9)  # 途中（出力端付近）
	visuals.update_item_icon()
	var icon = visuals.get_node("ItemIcon")
	# NE 方向への出力端は Y < 0（画面上方向）になるはず
	assert_lt(icon.position.y, 0.0, "NEパス上のアイコンはY<0のはず")


func test_CONVEYORは出力方向が2つのとき2本のパスを持つ():
	var conveyor = CONVEYOR_SCENE.instantiate()
	add_child_autofree(conveyor)
	conveyor.setup(0)
	var visuals = conveyor.get_node("ConveyorVisuals")
	visuals.set_output_directions([0, 1])
	assert_eq(visuals._paths.size(), 2)
