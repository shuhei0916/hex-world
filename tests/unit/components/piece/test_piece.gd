# gdlint:disable=constant-name
extends GutTest

const MINER_SCENE = preload("res://scenes/components/piece/miner_t2.tscn")
const SMELTER_SCENE = preload("res://scenes/components/piece/smelter_t2.tscn")
const ASSEMBLER_SCENE = preload("res://scenes/components/piece/assembler_t2.tscn")
const CONVEYOR_SCENE = preload("res://scenes/components/piece/conveyor.tscn")
const BRIDGE_SCENE = preload("res://scenes/components/piece/bridge.tscn")


class TestMachineCapacity:
	extends GutTest

	func test_機械の出力容量はレシピ1回分1になる():
		var p = SMELTER_SCENE.instantiate()
		add_child_autofree(p)
		p.setup()
		assert_eq(p.ejector.capacity, 1)

	func test_機械の入力容量はレシピ1回分1になる():
		var p = SMELTER_SCENE.instantiate()
		add_child_autofree(p)
		p.setup()
		assert_eq(p.get_node("Crafter").input_capacity, 1)


class TestPieceBasics:
	extends GutTest

	var piece: Piece

	func before_each():
		piece = SMELTER_SCENE.instantiate()
		add_child_autofree(piece)

	func test_セットアップでrotation_stateを設定できる():
		piece.setup(2)
		assert_eq(piece.rotation_state, 2)

	func test_add_itemでPieceにアイテムを追加できる():
		piece.add_item("iron", 10)
		assert_eq(piece.get_item_count("iron"), 10)

	func test_インベントリが満杯の場合はアイテムを受け入れない():
		piece.setup()  # レシピ適用で入力容量が1クラフト分(1)に絞られる
		piece.add_item("iron", 1)
		assert_false(piece.can_accept_item("copper"))


class TestPieceVisuals:
	extends GutTest

	var piece: Piece

	func before_each():
		piece = SMELTER_SCENE.instantiate()
		add_child_autofree(piece)

	func test_出力ポートが存在する場合に矢印が表示される():
		piece.port_direction = 0
		piece.port_hex = Vector2i(0, 0)
		piece.setup()

		assert_not_null(piece._output_arrow, "出力ポートがある場合、矢印Sprite2Dが生成されるべき")


class TestPieceOutputPorts:
	extends GutTest

	func test_port_direction2が設定されるとget_output_portsが2ポートを返す():
		var piece = SMELTER_SCENE.instantiate()
		add_child_autofree(piece)
		piece.port_direction = 0
		piece.port_direction2 = 1
		piece.setup()
		assert_eq(piece.get_output_ports().size(), 2)

	func test_port_direction2がデフォルトならget_output_portsは1ポートのまま():
		var piece = SMELTER_SCENE.instantiate()
		add_child_autofree(piece)
		piece.port_direction = 0
		piece.setup()
		assert_eq(piece.get_output_ports().size(), 1)


class TestPieceTransformation:
	extends GutTest
	var p: Piece

	func before_each():
		p = ASSEMBLER_SCENE.instantiate()
		p.setup()
		add_child_autofree(p)

	func test_ピースの回転に合わせてポートの向きも変更される():
		assert_eq(p.get_output_ports()[0].direction, 2)
		p.set_rotation_state((p.rotation_state + 1) % 6)
		assert_eq(p.get_output_ports()[0].direction, 1)

	func test_回転すると本体の形も回転後のマスに合わせて描き直す():
		p.set_rotation_state((p.rotation_state + 1) % 6)
		var outline: PackedVector2Array = p.get_node("Body").get_outline()
		for hex in p.get_hex_shape():
			var center := Layout.hex_to_pixel(Layout.make_default(), hex)
			assert_true(Geometry2D.is_point_in_polygon(center, outline))
		assert_eq(p.get_children().filter(func(c): return c is PieceBody).size(), 1)

	func test_回転前のピースの形状を取得できる():
		var result = p.get_hex_shape()
		assert_eq(result.size(), 4)
		assert_true(result[0] == Vector2i(-1, 0))
		assert_true(result[1] == Vector2i(0, 0))

	func test_回転後のピースの形状を取得できる():
		p.set_rotation_state((p.rotation_state + 1) % 6)
		var result = p.get_hex_shape()
		assert_true(result[0] == Vector2i(0, -1))

	func test_機械の出力アイテムは出力ポート端に表示される():
		var s = SMELTER_SCENE.instantiate()
		add_child_autofree(s)
		s.setup(0)
		s.ejector.add_item("iron_ingot", 1)
		s.ejector.tick(1.0)  # スライド完了させてポート端へ
		var visual = s.get_node("ItemEjectorVisual")
		visual.update_item_icon()
		var port = s.get_output_ports()[0]
		var layout = Layout.make_default()
		var expected = (
			Layout.hex_to_pixel(layout, port.hex)
			+ Layout.hex_to_pixel(layout, Hex.DIRECTIONS[port.direction]) * 0.5
		)
		assert_eq(visual.get_node("ItemIcon").position, expected)

	func test_機械の出力アイテム位置はピース回転に追従する():
		var s = SMELTER_SCENE.instantiate()
		add_child_autofree(s)
		s.setup(0)
		s.ejector.add_item("iron_ingot", 1)
		s.ejector.tick(1.0)
		var visual = s.get_node("ItemEjectorVisual")
		visual.update_item_icon()
		var before = visual.get_node("ItemIcon").position
		s.set_rotation_state((s.rotation_state + 1) % 6)
		visual.update_item_icon()
		assert_ne(visual.get_node("ItemIcon").position, before)

	func test_出力アイテムのスライド起点は出力hexの中心():
		# 複数hexのminerでは出力ポートhexがベースとずれる。progress0で出力hex中心に居るべき
		var m = MINER_SCENE.instantiate()
		add_child_autofree(m)
		m.setup(0)
		m.ejector.add_item("iron_ore", 1)  # progress 0（スライド開始前）
		var visual = m.get_node("ItemEjectorVisual")
		visual.update_item_icon()
		var port = m.get_output_ports()[0]
		var expected_center = Layout.hex_to_pixel(Layout.make_default(), port.hex)
		assert_almost_eq(visual.get_node("ItemIcon").position, expected_center, Vector2(0.1, 0.1))

	func test_出力アイテムはヘックスタイルより奥に描画される():
		var s = SMELTER_SCENE.instantiate()
		add_child_autofree(s)
		s.setup(0)
		var tile = null
		for child in s.get_children():
			if child is PieceBody:
				tile = child
				break
		assert_lt(s.get_node("ItemEjectorVisual/ItemIcon").z_index, tile.z_index)


class TestPieceAcceptor:
	extends GutTest

	func test_機械ピースのget_acceptorはCrafterを返す():
		var p = SMELTER_SCENE.instantiate()
		add_child_autofree(p)
		assert_eq(p.get_acceptor(), p.get_node("Crafter"))

	func test_コンベアのget_acceptorはConveyorLogicを返す():
		var p = CONVEYOR_SCENE.instantiate()
		add_child_autofree(p)
		assert_eq(p.get_acceptor(), p.get_node("ConveyorLogic"))

	func test_minerは入力を受け付けない():
		# miner はレシピ入力が無く入力容量0なので、何も受け入れない
		var p = MINER_SCENE.instantiate()
		add_child_autofree(p)
		p.setup()
		assert_false(p.can_accept_item("iron_ore"))

	func test_搬入チェストとハブはそれぞれの部品が受け入れ口になる():
		var chest = load("res://scenes/components/piece/chest_in.tscn").instantiate()
		add_child_autofree(chest)
		assert_eq(chest.get_acceptor(), chest.get_node("ChestInput"))
		var hub = load("res://scenes/components/piece/hub.tscn").instantiate()
		add_child_autofree(hub)
		assert_eq(hub.get_acceptor(), hub.get_node("Hub"))

	func test_搬出チェストは何も受け入れない():
		var chest = load("res://scenes/components/piece/chest_out.tscn").instantiate()
		add_child_autofree(chest)
		assert_null(chest.get_acceptor())


class TestPieceKind:
	extends GutTest

	func test_コンベアかどうかは種類で決まり見た目の部品の有無に左右されない():
		var p = CONVEYOR_SCENE.instantiate()
		add_child_autofree(p)
		p.get_node("ConveyorVisuals").free()
		assert_true(p.is_conveyor())

	func test_橋はベルトの動きの部品を持つがコンベアではない():
		var p = BRIDGE_SCENE.instantiate()
		add_child_autofree(p)
		assert_false(p.is_conveyor())

	func test_機械はコンベアではない():
		var p = SMELTER_SCENE.instantiate()
		add_child_autofree(p)
		assert_false(p.is_conveyor())


class TestPieceRoles:
	extends GutTest

	func test_製錬所は初期化時に自動的に適切なレシピとポートが設定される():
		var p = SMELTER_SCENE.instantiate()
		add_child(p)
		autofree(p)
		p.setup()

		assert_not_null(p.current_recipe, "製錬所はレシピを持つべき")
		assert_gt(p.get_output_ports().size(), 0, "製錬所は出力ポートを持つべき")

	func test_採掘機は時間経過でアイテムを自動生産する():
		# 採掘機は Input ノードを持たないが、crafter が Output へ直接生産する
		var p = MINER_SCENE.instantiate()
		add_child(p)
		autofree(p)
		p.setup()

		p.tick(1.1)
		assert_eq(p.get_item_count("iron_ore"), 1)

	func test_製錬所は同じ種類の機械の別レシピの材料も受け入れる():
		var p = SMELTER_SCENE.instantiate()
		add_child_autofree(p)
		p.setup()
		assert_true(p.can_accept_item("copper_ore"))

	func test_製錬所に銅鉱石を入れると銅インゴットが作られる():
		var p = SMELTER_SCENE.instantiate()
		add_child_autofree(p)
		p.setup()
		p.add_item("copper_ore", 1)
		p.tick(0.0)
		p.tick(10.0)
		assert_eq(p.get_item_count("copper_ingot"), 1)


class TestPieceMetadata:
	extends GutTest

	func test_ピースは名前を持つ():
		var p = MINER_SCENE.instantiate()
		add_child_autofree(p)
		assert_eq(p.piece_name, "Miner")
