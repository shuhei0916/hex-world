# gdlint:disable=duplicated-load
extends GutTest

const CONVEYOR_SCENE = preload("res://scenes/components/piece/conveyor.tscn")

var piece_scene = load("res://scenes/components/piece/smelter_t2.tscn")
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


func test_分岐コンベアのベルトは入口の辺から中心を通って各出口の辺へ直線で描かれる():
	# 入力は West(3)、出力は East(0) と NE(1) に分岐
	var conveyor = CONVEYOR_SCENE.instantiate()
	add_child_autofree(conveyor)
	conveyor.setup(0)
	var visuals = conveyor.get_node("ConveyorVisuals")
	visuals.set_output_directions([0, 1])
	var layout = Layout.make_default()
	var in_edge = Layout.hex_to_pixel(layout, Hex.hex_directions[3]) * 0.5
	var ne_edge = Layout.hex_to_pixel(layout, Hex.hex_directions[1]) * 0.5
	assert_eq(
		visuals._paths[1],
		PackedVector2Array([in_edge, Vector2.ZERO, ne_edge]),
		"NEへの分岐は入口→中心→出口の直線"
	)


func test_合流コンベアは主入力以外の入力の辺から中心へ合流用のベルトを描く():
	# 出力 East(0)。主入力 West(3)、もう1本は SE(5) から合流する
	var conveyor = CONVEYOR_SCENE.instantiate()
	add_child_autofree(conveyor)
	conveyor.setup(0)
	var visuals = conveyor.get_node("ConveyorVisuals")
	visuals.set_input_directions([3, 5])
	var layout = Layout.make_default()
	var se_edge = Layout.hex_to_pixel(layout, Hex.hex_directions[5]) * 0.5
	assert_eq(visuals._paths.size(), 1, "出口へのパスは主入力からの1本のまま")
	assert_eq(visuals._merge_paths, [PackedVector2Array([se_edge, Vector2.ZERO])])


func test_入力が1つなら合流用のベルトは描かない():
	var conveyor = CONVEYOR_SCENE.instantiate()
	add_child_autofree(conveyor)
	conveyor.setup(0)
	var visuals = conveyor.get_node("ConveyorVisuals")
	visuals.set_input_directions([3])
	assert_eq(visuals._merge_paths, [])
	assert_eq(visuals._input_direction, 3)


class TestBeltArrowContinuity:
	extends GutTest

	## ベルトの矢印が、隣り合うコンベアの境目で途切れずに流れて見えるための条件

	func before_each():
		HubGoals.reset()

	func after_each():
		HubGoals.reset()

	func test_矢印は1マスに決まった本数が等間隔に並ぶ():
		var fractions = ConveyorVisuals.arrow_fractions(0.123)
		assert_eq(fractions.size(), ConveyorVisuals.ARROWS_PER_PIECE)
		var gap = 1.0 / ConveyorVisuals.ARROWS_PER_PIECE
		for i in range(1, fractions.size()):
			assert_almost_eq(fractions[i] - fractions[i - 1], gap, 0.0001)

	func test_矢印の位置は時刻だけで決まり_コンベアごとの設置時刻に左右されない():
		# 隣り合うコンベアが同じ時計を使うので、出口を出た矢印がそのまま次の入口に現れる
		assert_eq(ConveyorVisuals.arrow_fractions(4.56), ConveyorVisuals.arrow_fractions(4.56))
		var conveyor_scene = load("res://scenes/components/piece/conveyor.tscn")
		var first = conveyor_scene.instantiate()
		add_child_autofree(first)
		first.get_node("ConveyorVisuals")._process(5.0)
		var second = conveyor_scene.instantiate()
		add_child_autofree(second)
		assert_eq(
			first.get_node("ConveyorVisuals").current_arrow_fractions(),
			second.get_node("ConveyorVisuals").current_arrow_fractions()
		)

	func test_矢印は1マスを搬送時間ちょうどで通り抜ける():
		# 矢印の間隔ぶん進む時間 = 搬送時間 / 本数。その時間が経つと同じ並びに戻る
		var period = TransferBuffer.TRANSFER_TIME / ConveyorVisuals.ARROWS_PER_PIECE
		var now = ConveyorVisuals.arrow_fractions(1.0)
		var later = ConveyorVisuals.arrow_fractions(1.0 + period)
		for i in now.size():
			assert_almost_eq(later[i], now[i], 0.0001)

	func test_矢印は入口から出口へ向かって進む():
		var before = ConveyorVisuals.arrow_fractions(1.0)[0]
		var after = ConveyorVisuals.arrow_fractions(1.01)[0]
		assert_gt(after, before)

	func test_コンベア高速化を研究すると矢印も速く流れる():
		var normal = ConveyorVisuals.arrow_fractions(0.05)[0]
		HubGoals.researched = {"belt_speed_1": true, "belt_speed_2": true}
		var fast = ConveyorVisuals.arrow_fractions(0.05)[0]
		assert_almost_eq(fast, normal * 2.0, 0.0001)

	func test_曲がったコンベアでも直進のコンベアでも矢印の本数は同じ():
		var straight = PackedVector2Array([Vector2(-36, 0), Vector2(0, 0), Vector2(36, 0)])
		var curved = ConveyorVisuals.sample_bezier(
			Vector2(-36, 0), Vector2.ZERO, Vector2(18, 31), ConveyorVisuals.CURVE_SEGMENTS
		)
		var fractions = ConveyorVisuals.arrow_fractions(0.2)
		assert_eq(
			ConveyorVisuals.arrow_points(straight, fractions).size(),
			ConveyorVisuals.arrow_points(curved, fractions).size()
		)

	func test_矢印は経路の長さに対する割合の位置に置かれる():
		var path = PackedVector2Array([Vector2(0, 0), Vector2(100, 0)])
		var points = ConveyorVisuals.arrow_points(path, [0.25, 0.75])
		assert_almost_eq(points[0]["position"].x, 25.0, 0.01)
		assert_almost_eq(points[1]["position"].x, 75.0, 0.01)
		assert_eq(points[0]["tangent"], Vector2(1, 0))

	func test_合流の半分の経路には_前半にある矢印だけが置かれる():
		# 合流のベルトは辺から中心まで（1マスの前半）。本線の前半と同じ位置に矢印が来る
		var stub = PackedVector2Array([Vector2(-50, 0), Vector2(0, 0)])
		var points = ConveyorVisuals.arrow_points(stub, [0.25, 0.75], 0.5)
		assert_eq(points.size(), 1)
		assert_almost_eq(points[0]["position"].x, -25.0, 0.01)

	func _inside_cell(point: Vector2) -> bool:
		# pointy-top の六角形のマス。辺の中点までの距離（内接円の半径）を超えない
		var inradius = (
			Layout.hex_to_pixel(Layout.make_default(), Hex.hex_directions[0]).length() * 0.5
		)
		for dir in 6:
			var normal = (
				Layout.hex_to_pixel(Layout.make_default(), Hex.hex_directions[dir]).normalized()
			)
			if point.dot(normal) > inradius + 0.01:
				return false
		return true

	func test_出口の辺にかかった矢印はマスの外へはみ出さない():
		var edge_mid = Layout.hex_to_pixel(Layout.make_default(), Hex.hex_directions[0]) * 0.5
		var polygons = ConveyorVisuals.chevron_polygons(edge_mid, Vector2(1, 0))
		assert_gt(polygons.size(), 0, "マスの中にある部分は描く")
		for polygon in polygons:
			for point in polygon:
				assert_true(_inside_cell(point), str(point))

	func test_入口の辺にかかった矢印もマスの外へはみ出さない():
		var edge_mid = Layout.hex_to_pixel(Layout.make_default(), Hex.hex_directions[3]) * 0.5
		for polygon in ConveyorVisuals.chevron_polygons(edge_mid, Vector2(1, 0)):
			for point in polygon:
				assert_true(_inside_cell(point), str(point))

	func test_マスの中ほどの矢印は欠けずに元の形のまま():
		var polygons = ConveyorVisuals.chevron_polygons(Vector2.ZERO, Vector2(1, 0))
		assert_eq(polygons.size(), 1)
		assert_eq(
			polygons[0].size(), ConveyorVisuals.chevron_shape(Vector2.ZERO, Vector2(1, 0)).size()
		)

	func test_矢印はくの字で_斜めに流れても向きを読み違えない():
		# 正三角形に近い三角形は120度回すと同じ形になり、斜めの流れで向きが逆に見える。
		# くの字なら先端は1点だけで、反対側には左右の腕の端が2点並ぶ
		for angle in [0.0, PI / 3.0, -PI / 6.0, PI * 2.0 / 3.0]:
			var tangent = Vector2.RIGHT.rotated(angle)
			var shape = ConveyorVisuals.chevron_shape(Vector2.ZERO, tangent)
			var along = Array(shape).map(func(p): return snappedf(p.dot(tangent), 0.01))
			var front = along.max()
			var back = along.min()
			assert_eq(along.count(front), 1, "先端は1点 (角度 %.2f)" % angle)
			assert_eq(along.count(back), 2, "後ろは腕の端の2点 (角度 %.2f)" % angle)
			assert_gt(front - back, 0.0)
