# gdlint:disable=constant-name
extends GutTest

const CONVEYOR_SCENE = preload("res://scenes/components/piece/conveyor.tscn")
const SMELTER_SCENE = preload("res://scenes/components/piece/smelter_t2.tscn")
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

	func test_slot1がコンベア後半に達したとき2個目を受け入れられる():
		conveyor.add_item("iron_plate", 1)
		conveyor.get_node("ConveyorLogic").tick(0.25)  # progress = 0.5 (後半に到達)
		assert_true(conveyor.can_accept_item("iron_ore"))

	func test_slot1がコンベア前半のとき2個目を受け入れられない():
		conveyor.add_item("iron_plate", 1)
		conveyor.get_node("ConveyorLogic").tick(0.1)  # progress = 0.2 (前半)
		assert_false(conveyor.can_accept_item("iron_ore"))

	func test_slot2にアイテムを追加するとget_item_countに反映される():
		conveyor.add_item("iron_plate", 1)
		conveyor.get_node("ConveyorLogic").tick(0.25)  # slot1が後半へ
		conveyor.add_item("iron_ore", 1)
		assert_eq(conveyor.get_item_count("iron_ore"), 1)

	func test_slot1搬出後slot2がslot1に昇格しget_held_itemで取得できる():
		var logic = conveyor.get_node("ConveyorLogic")
		conveyor.add_item("iron_plate", 1)
		logic.tick(0.25)  # slot1が後半へ
		conveyor.add_item("iron_ore", 1)
		logic.tick(0.25)  # slot1が搬出完了（接続先なし→保持継続）→ここでは搬出されない
		# 接続先のない状態では搬出されないので、clearを直接呼んでslot1搬出をシミュレート
		logic._buffer.clear()
		assert_eq(logic.get_held_item(), "iron_ore")

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

	func test_直線ベルトもプロシージャル描画を使い子ノードはItemIconとItemIcon2のみ():
		assert_eq(conveyor.get_node("ConveyorVisuals").get_child_count(), 2)

	func test_slot2保持中はItemIcon2が表示される():
		conveyor.add_item("iron_plate", 1)
		conveyor.get_node("ConveyorLogic").tick(0.25)  # slot1が後半へ
		conveyor.add_item("iron_ore", 1)
		conveyor.get_node("ConveyorVisuals").update_item_icon()
		var icon2: Sprite2D = conveyor.get_node_or_null("ConveyorVisuals/ItemIcon2")
		assert_true(icon2 != null and icon2.visible)

	func test_進行度1でアイコンは出口の端にある():
		# 接続先が無い終端でも手前で止めない（詰まったときの間隔を0.5にそろえるため）
		conveyor.add_item("iron_plate", 1)
		conveyor.get_node("ConveyorLogic").tick(0.5)  # progress = 1.0（端まで到達）
		conveyor.get_node("ConveyorVisuals").update_item_icon()
		var path = conveyor.get_node("ConveyorVisuals")._path
		var end_pos = path[path.size() - 1]
		var icon_pos = conveyor.get_node("ConveyorVisuals/ItemIcon").position
		assert_almost_eq(icon_pos, end_pos, Vector2(1.0, 1.0))

	func test_slot2非保持時はItemIcon2が非表示():
		conveyor.add_item("iron_plate", 1)
		conveyor.get_node("ConveyorVisuals").update_item_icon()
		assert_false(conveyor.get_node("ConveyorVisuals/ItemIcon2").visible)

	func test_ItemIcon2の位置はslot2のprogress_ratioに従う():
		conveyor.add_item("iron_plate", 1)
		conveyor.get_node("ConveyorLogic").tick(0.25)  # slot1が後半へ
		conveyor.add_item("iron_ore", 1)
		# slot2はprogress_2=0なので入力エッジにある
		conveyor.get_node("ConveyorVisuals").update_item_icon()
		var in_edge = conveyor.get_node("ConveyorVisuals")._path[0]
		assert_almost_eq(
			conveyor.get_node("ConveyorVisuals/ItemIcon2").position, in_edge, Vector2(0.1, 0.1)
		)

	func test_slot1搬出後slot2がslot1に昇格しslot2は空になる():
		var logic = conveyor.get_node("ConveyorLogic")
		conveyor.add_item("iron_plate", 1)
		logic.tick(0.25)
		conveyor.add_item("iron_ore", 1)
		# slot1搬出をシミュレート
		logic._buffer.clear()
		# slot2→slot1に昇格、slot2は空
		assert_eq(logic._buffer.held_item_2, "")


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

	func test_出口が1本のコンベアは詰まっているとき出口の端まで進んで待つ():
		gm.place_piece(CONVEYOR_SCENE, Hex.new(0, 0), 0)  # East → (1,0)
		gm.place_piece(CONVEYOR_SCENE, Hex.new(1, 0), 0)
		var conv_a = gm.get_piece_at_hex(Hex.new(0, 0))
		gm.get_piece_at_hex(Hex.new(1, 0)).add_item("iron_plate", 1)
		conv_a.add_item("iron_plate", 1)
		conv_a.get_node("ConveyorLogic").tick(TransferBuffer.TRANSFER_TIME)
		assert_eq(conv_a.get_node("ConveyorLogic").get_progress_ratio(), 1.0, "分岐でなければ端(1.0)で待つべき")

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


class TestConveyorLogicRoundRobin:
	extends GutTest

	var gm

	func before_each():
		gm = Chunk.new()
		add_child_autofree(gm)
		gm.create_hex_grid(3)

	func test_ConveyorLogicは接続先が2つのときget_target_directionで次の排出方向を返す():
		gm.place_piece(CONVEYOR_SCENE, Hex.new(0, 0))  # A: East
		gm.place_piece(CONVEYOR_SCENE, Hex.new(1, 0))  # B: East（East方向へ続く）
		gm.place_piece(CONVEYOR_SCENE, Hex.new(1, -1), 5)  # C: NE（自然な分岐）
		var a = gm.get_piece_at_hex(Hex.new(0, 0))
		a.add_item("iron_ore", 1)
		assert_ne(a.get_node("ConveyorLogic").get_target_direction(), -1)


# 分岐コンベアは入口→中心を進み、中心で行き先（出力方向）を確定してから出口へ進む
# A(0,0) East から、B(1,0) East（ポート）と C(1,-1) NE（自然な分岐）へ分岐する
class TestConveyorBranchRouting:
	extends GutTest

	const HALF = TransferBuffer.TRANSFER_TIME * 0.5

	var chunk: Chunk
	var a: Piece
	var logic: ConveyorLogic

	func before_each():
		chunk = Chunk.new()
		add_child_autofree(chunk)
		chunk.create_hex_grid(3)
		chunk.place_piece(CONVEYOR_SCENE, Hex.new(0, 0))
		chunk.place_piece(CONVEYOR_SCENE, Hex.new(1, 0))
		chunk.place_piece(CONVEYOR_SCENE, Hex.new(1, -1), 5)
		a = chunk.get_piece_at_hex(Hex.new(0, 0))
		logic = a.get_node("ConveyorLogic")

	func _piece_in_direction(direction: int) -> Piece:
		return chunk.get_piece_at_hex(Hex.neighbor(Hex.new(0, 0), direction))

	func test_中心を過ぎたあとに出口の空き状況が変わっても行き先の方向は変わらない():
		a.add_item("iron_ore", 1)
		logic.tick(HALF * 1.2)
		var locked_direction = logic.get_target_direction()
		_piece_in_direction(locked_direction).add_item("iron_ore", 1)  # 行き先を詰まらせる
		assert_eq(logic.get_target_direction(), locked_direction, "中心で決めた行き先は変わらないべき")

	func test_中心を過ぎたあとに接続が更新されても同じ方向の出口が残っていれば行き先は変わらない():
		a.add_item("iron_ore", 1)
		logic.tick(HALF * 1.2)
		var locked_direction = logic.get_target_direction()
		# 行き先のコンベアを置き直す（分岐を延長したときと同様に A の接続が更新される）
		var target_hex = Hex.neighbor(Hex.new(0, 0), locked_direction)
		var rotation = _piece_in_direction(locked_direction).rotation_state
		chunk.remove_piece_at(target_hex)
		chunk.place_piece(CONVEYOR_SCENE, target_hex, rotation)
		assert_eq(logic.get_target_direction(), locked_direction, "同じ方向の出口が残っていれば行き先は変わらないべき")

	func test_中心を過ぎたあとに行き先の出口が撤去されると残っている出口へ進む():
		a.add_item("iron_ore", 1)
		logic.tick(HALF * 1.2)
		var locked_direction = logic.get_target_direction()
		var other = _piece_in_direction(1 - locked_direction)  # 行き先は E(0) か NE(1)
		chunk.remove_piece_at(Hex.neighbor(Hex.new(0, 0), locked_direction))
		logic.tick(HALF)
		assert_eq(other.get_node("ConveyorLogic").get_held_item(), "iron_ore", "残っている出口へ渡されるべき")

	func test_全部の出口が詰まっているとアイテムは中心で待つ():
		_piece_in_direction(0).add_item("iron_ore", 1)
		_piece_in_direction(1).add_item("iron_ore", 1)
		a.add_item("iron_ore", 1)
		logic.tick(TransferBuffer.TRANSFER_TIME)
		assert_eq(logic.get_progress_ratio(), 0.5, "全出口が詰まっているとき中心(0.5)で待つべき")

	func test_中心で待っていたアイテムは出口が空くと進み出して搬出される():
		chunk.place_piece(CONVEYOR_SCENE, Hex.new(2, 0))  # B の下流（B を空けるため）
		var b = _piece_in_direction(0)
		b.add_item("iron_ore", 1)
		_piece_in_direction(1).add_item("iron_ore", 1)
		a.add_item("copper_ore", 1)
		logic.tick(TransferBuffer.TRANSFER_TIME)  # 中心で待つ
		b.get_node("ConveyorLogic").tick(TransferBuffer.TRANSFER_TIME)  # B が下流へ流して空く
		logic.tick(TransferBuffer.TRANSFER_TIME)
		assert_eq(b.get_node("ConveyorLogic").get_held_item(), "copper_ore", "空いた出口Bへ搬出されるべき")

	func test_全部の出口が詰まって中心で待っている間は次のアイテムを受け入れない():
		_piece_in_direction(0).add_item("iron_ore", 1)
		_piece_in_direction(1).add_item("iron_ore", 1)
		a.add_item("iron_ore", 1)
		logic.tick(TransferBuffer.TRANSFER_TIME)  # 中心で待つ
		assert_false(logic.can_accept_item("iron_ore"), "中心で待っている間は2個目を受け入れないべき（アイコンが重なるため）")

	func test_中心で待っていたアイテムの行き先が決まると次のアイテムを再び受け入れる():
		chunk.place_piece(CONVEYOR_SCENE, Hex.new(2, 0))  # B の下流（B を空けるため）
		var b = _piece_in_direction(0)
		b.add_item("iron_ore", 1)
		_piece_in_direction(1).add_item("iron_ore", 1)
		a.add_item("copper_ore", 1)
		logic.tick(TransferBuffer.TRANSFER_TIME)  # 中心で待つ
		b.get_node("ConveyorLogic").tick(TransferBuffer.TRANSFER_TIME)  # B が空く
		logic.tick(0.01)  # 行き先が B に決まり、中心を過ぎる
		assert_true(logic.can_accept_item("iron_ore"), "行き先が決まれば次のアイテムを受け入れるべき")
