# gdlint:disable=constant-name
extends GutTest

const CONVEYOR_SCENE = preload("res://scenes/components/piece/conveyor.tscn")
const SMELTER_SCENE = preload("res://scenes/components/piece/smelter.tscn")
const Chunk = preload("res://scenes/components/chunk/chunk.gd")


class TestConveyorShape:
	extends GutTest

	func test_conveyorは1ヘックス形状である():
		var piece = CONVEYOR_SCENE.instantiate()
		add_child_autofree(piece)
		assert_eq(piece.piece_shape.size(), 1)

	func test_conveyorはInputノードを持たない():
		var piece = CONVEYOR_SCENE.instantiate()
		add_child_autofree(piece)
		assert_null(piece.get_node_or_null("ItemAcceptor"))

	func test_conveyorはOutputノードを持たない():
		var piece = CONVEYOR_SCENE.instantiate()
		add_child_autofree(piece)
		assert_null(piece.get_node_or_null("ItemEjector"))


class TestConveyorLogic:
	extends GutTest

	var conveyor

	func before_each():
		conveyor = CONVEYOR_SCENE.instantiate()
		add_child_autofree(conveyor)
		conveyor.setup()

	func test_アイテム保持中はcan_accept_itemがfalseを返す():
		conveyor.add_item("iron_plate", 1)
		assert_false(conveyor.can_accept_item("iron_plate"))

	func test_ConveyorLogicはadd_itemで受け入れcan_accept_itemで容量を答える():
		var logic = conveyor.get_node("ConveyorLogic")
		logic.add_item("iron_plate", 1)
		assert_false(logic.can_accept_item("iron_plate"))

	func test_add_itemしたアイテムはget_item_countで数えられる():
		conveyor.add_item("iron_plate", 1)
		assert_eq(conveyor.get_item_count("iron_plate"), 1)

	func test_接続先がない場合tick0_5でもアイテムは保持されたまま():
		conveyor.add_item("iron_plate", 1)
		conveyor.get_node("ConveyorLogic").tick(0.5)
		assert_eq(conveyor.get_item_count("iron_plate"), 1)

	func test_接続先がない場合tick0_4でもアイテムは保持されたまま():
		conveyor.add_item("iron_plate", 1)
		conveyor.get_node("ConveyorLogic").tick(0.4)
		assert_eq(conveyor.get_item_count("iron_plate"), 1)

	func test_committed方向が塞がれても別方向には排出せず待機する():
		# East(0)にコミットした後、Eastが満杯でもNE(1)には排出しない
		var logic = conveyor.get_node("ConveyorLogic")
		var dest_e = CONVEYOR_SCENE.instantiate()
		add_child_autofree(dest_e)
		var dest_ne = CONVEYOR_SCENE.instantiate()
		add_child_autofree(dest_ne)
		logic.set_connected_pieces([dest_e, dest_ne], [0, 1])
		conveyor.add_item("iron_plate", 1)  # _committed_direction = 0 (East)
		dest_e.add_item("iron_plate", 1)  # Eastを満杯にする
		logic.tick(TransferBuffer.TRANSFER_TIME)
		assert_eq(conveyor.get_item_count("iron_plate"), 1, "Eastが塞がれた場合NEへ排出すべきでない")

	func test_搬送中に接続先の受け入れ状態が変わっても進行方向は変わらない():
		# add_item 時に方向0(East)が選ばれた後、接続先を差し替えても方向0を保持するべき
		var logic = conveyor.get_node("ConveyorLogic")
		var dest_e = CONVEYOR_SCENE.instantiate()
		add_child_autofree(dest_e)
		logic.set_connected_pieces([dest_e], [0])
		conveyor.add_item("iron_plate", 1)
		assert_eq(logic.get_target_direction(), 0)
		# 接続先を空配列に切り替えても方向は変わらないべき
		logic.set_connected_pieces([], [])
		assert_eq(logic.get_target_direction(), 0, "搬送中は進行方向を維持するべき")


class TestConveyorVisuals:
	extends GutTest

	var conveyor

	func before_each():
		conveyor = CONVEYOR_SCENE.instantiate()
		add_child_autofree(conveyor)
		conveyor.setup()

	func test_ベルト描画はConveyorVisualsコンポーネントが担う():
		assert_eq(conveyor.get_node("ConveyorVisuals")._path.size(), 3)

	func test_アイテム保持中はアイコンが表示される():
		conveyor.add_item("iron_plate", 1)
		conveyor.get_node("ConveyorVisuals").update_item_icon()
		var icon: Sprite2D = conveyor.get_node_or_null("ConveyorVisuals/ItemIcon")
		assert_true(icon != null and icon.visible)

	func test_アイテム非保持時はアイコンが非表示():
		# 何も保持していない状態ではアイコンは出ない
		conveyor.get_node("ConveyorVisuals").update_item_icon()
		assert_false(conveyor.get_node("ConveyorVisuals/ItemIcon").visible)

	func test_進行度0でアイコンは入力エッジ位置にある():
		conveyor.add_item("iron_plate", 1)
		conveyor.get_node("ConveyorVisuals").update_item_icon()
		var in_edge = conveyor.get_node("ConveyorVisuals")._path[0]
		assert_almost_eq(
			conveyor.get_node("ConveyorVisuals/ItemIcon").position, in_edge, Vector2(0.1, 0.1)
		)

	func test_アイテムアイコンはコンベアベルトより手前に描画される():
		var icon: Sprite2D = conveyor.get_node("ConveyorVisuals/ItemIcon")
		assert_gt(icon.z_index, conveyor.get_node("ConveyorVisuals").z_index)

	func test_進行度半分でアイコンはライン中央にある():
		conveyor.add_item("iron_plate", 1)
		conveyor.get_node("ConveyorLogic").tick(0.25)
		conveyor.get_node("ConveyorVisuals").update_item_icon()
		var center = conveyor.get_node("ConveyorVisuals")._path[1]
		assert_almost_eq(
			conveyor.get_node("ConveyorVisuals/ItemIcon").position, center, Vector2(0.1, 0.1)
		)

	func test_sample_bezierはsegments_plus_1点を返す():
		var pts = ConveyorVisuals.sample_bezier(Vector2(-1, 0), Vector2.ZERO, Vector2(1, 0), 4)
		assert_eq(pts.size(), 5)

	func test_sample_bezierの始点と終点はp0とp2():
		var p0 = Vector2(-10, 5)
		var p2 = Vector2(10, -5)
		var pts = ConveyorVisuals.sample_bezier(p0, Vector2.ZERO, p2, 6)
		assert_almost_eq(pts[0], p0, Vector2(0.001, 0.001))
		assert_almost_eq(pts[pts.size() - 1], p2, Vector2(0.001, 0.001))

	func test_直線ベルトのパスは3点():
		assert_eq(conveyor.get_node("ConveyorVisuals")._path.size(), 3)

	func test_直線ベルトもプロシージャル描画を使い子ノードはItemIconのみ():
		assert_eq(conveyor.get_node("ConveyorVisuals").get_child_count(), 1)


class TestConveyorConnection:
	extends GutTest

	var gm

	func before_each():
		gm = Chunk.new()
		add_child_autofree(gm)
		gm.create_hex_grid(3)

	func test_出力ポートの先のピースに接続される():
		gm.place_piece(CONVEYOR_SCENE, Hex.new(0, 0))
		gm.place_piece(CONVEYOR_SCENE, Hex.new(1, 0))
		var conveyor = gm.get_piece_at_hex(Hex.new(0, 0))
		var chest = gm.get_piece_at_hex(Hex.new(1, 0))
		assert_true(chest in conveyor.get_connected_pieces())

	func test_tick0_5で接続先ピースへアイテムが搬出される():
		gm.place_piece(CONVEYOR_SCENE, Hex.new(0, 0))
		gm.place_piece(CONVEYOR_SCENE, Hex.new(1, 0))
		var conveyor = gm.get_piece_at_hex(Hex.new(0, 0))
		var chest = gm.get_piece_at_hex(Hex.new(1, 0))
		conveyor.add_item("iron_plate", 1)
		conveyor.get_node("ConveyorLogic").tick(0.5)
		assert_eq(chest.get_item_count("iron_plate"), 1)

	func test_tick0_4では接続先にアイテムが渡らない():
		gm.place_piece(CONVEYOR_SCENE, Hex.new(0, 0))
		gm.place_piece(CONVEYOR_SCENE, Hex.new(1, 0))
		var conveyor = gm.get_piece_at_hex(Hex.new(0, 0))
		var chest = gm.get_piece_at_hex(Hex.new(1, 0))
		conveyor.add_item("iron_plate", 1)
		conveyor.get_node("ConveyorLogic").tick(0.4)
		assert_eq(chest.get_item_count("iron_plate"), 0)

	func test_転送後コンベアは空になる():
		gm.place_piece(CONVEYOR_SCENE, Hex.new(0, 0))
		gm.place_piece(CONVEYOR_SCENE, Hex.new(1, 0))
		var conveyor = gm.get_piece_at_hex(Hex.new(0, 0))
		conveyor.add_item("iron_plate", 1)
		conveyor.get_node("ConveyorLogic").tick(0.5)
		assert_eq(conveyor.get_item_count("iron_plate"), 0)

	func test_転送後コンベアは再び受け入れ可能になる():
		gm.place_piece(CONVEYOR_SCENE, Hex.new(0, 0))
		gm.place_piece(CONVEYOR_SCENE, Hex.new(1, 0))
		var conveyor = gm.get_piece_at_hex(Hex.new(0, 0))
		conveyor.add_item("iron_plate", 1)
		conveyor.get_node("ConveyorLogic").tick(0.5)
		assert_true(conveyor.can_accept_item("iron_plate"))

	func test_機械のOutputからコンベアへアイテムがpushされる():
		gm.place_piece(SMELTER_SCENE, Hex.new(-1, 2))
		gm.place_piece(CONVEYOR_SCENE, Hex.new(0, 2))
		var smelter = gm.get_piece_at_hex(Hex.new(-1, 2))
		var conveyor = gm.get_piece_at_hex(Hex.new(0, 2))
		smelter.add_to_output("iron_ingot", 1)
		smelter.tick(1.0)  # スライド完了→コンベアへ排出
		assert_eq(conveyor.get_item_count("iron_ingot"), 1)

	func test_コンベアチェーンでアイテムが1個ずつ流れる():
		gm.place_piece(CONVEYOR_SCENE, Hex.new(0, 0), 0)  # East → (1,0)
		gm.place_piece(CONVEYOR_SCENE, Hex.new(1, 0), 0)  # East → (2,0)
		gm.place_piece(CONVEYOR_SCENE, Hex.new(2, 0))
		var conv_a = gm.get_piece_at_hex(Hex.new(0, 0))
		var conv_b = gm.get_piece_at_hex(Hex.new(1, 0))
		conv_a.add_item("iron_plate", 1)
		conv_a.get_node("ConveyorLogic").tick(0.5)
		assert_eq(conv_b.get_item_count("iron_plate"), 1)

	func test_接続先が受け入れ不可の間アイテムは保持されたまま消えない():
		gm.place_piece(CONVEYOR_SCENE, Hex.new(0, 0), 0)  # East → (1,0)
		gm.place_piece(CONVEYOR_SCENE, Hex.new(1, 0), 0)  # East → (2,0)
		var conv_a = gm.get_piece_at_hex(Hex.new(0, 0))
		var conv_b = gm.get_piece_at_hex(Hex.new(1, 0))
		conv_b.add_item("iron_plate", 1)
		conv_a.add_item("iron_plate", 1)
		conv_a.get_node("ConveyorLogic").tick(0.5)
		assert_eq(conv_a.get_item_count("iron_plate"), 1)

	func test_接続先が受け入れ可能になったらその後のtickで転送される():
		gm.place_piece(CONVEYOR_SCENE, Hex.new(0, 0), 0)  # East → (1,0)
		gm.place_piece(CONVEYOR_SCENE, Hex.new(1, 0), 0)  # East → (2,0)
		gm.place_piece(CONVEYOR_SCENE, Hex.new(2, 0))
		var conv_a = gm.get_piece_at_hex(Hex.new(0, 0))
		var conv_b = gm.get_piece_at_hex(Hex.new(1, 0))
		conv_b.add_item("iron_plate", 1)
		conv_a.add_item("iron_plate", 1)
		conv_a.get_node("ConveyorLogic").tick(0.5)  # B が保持中なので渡せない
		conv_b.get_node("ConveyorLogic").tick(0.5)  # B が chest へ搬出し空になる
		conv_a.get_node("ConveyorLogic").tick(0.5)  # A から B へ渡れるはず
		assert_eq(conv_b.get_item_count("iron_plate"), 1)

	func test_曲がり角コンベアの入力エッジが実際の入力方向を向く():
		# (0,0)[East出力] → (1,0)[NW出力=rotation4] → (1,-1) のチェーン
		# (1,0)のコンベアは West(3) 側から入力を受け取るべき
		gm.place_piece(CONVEYOR_SCENE, Hex.new(0, 0), 0)  # East 方向
		gm.place_piece(CONVEYOR_SCENE, Hex.new(1, 0), 4)  # NW 方向
		gm.place_piece(CONVEYOR_SCENE, Hex.new(1, -1), 0)  # East 方向（接続先）
		var bend = gm.get_piece_at_hex(Hex.new(1, 0))
		var layout = Layout.make_default()
		var in_edge = bend.get_node("ConveyorVisuals")._path[0]
		var expected = Layout.hex_to_pixel(layout, Hex.hex_directions[3]) * 0.5
		assert_almost_eq(in_edge.x, expected.x, 0.1)
