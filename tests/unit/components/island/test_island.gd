# gdlint:disable=constant-name
extends GutTest

const Island = preload("res://scenes/components/island/island.gd")


class TestGridLogic:
	extends GutTest

	var gm

	func before_each():
		gm = Island.new()
		add_child_autofree(gm)
		gm.clear_grid()

	func test_指定した範囲のグリッドを生成できる():
		gm.create_hex_grid(2)
		assert_eq(gm.get_grid_hex_count(), 19, "半径2のグリッドは19マスであるべき")
		assert_true(gm.is_inside_grid(Hex.new(0, 0)))
		assert_false(gm.is_inside_grid(Hex.new(3, 0)), "範囲外は登録されていないべき")

	func test_グリッド状態を完全にクリアできる():
		gm.register_grid_hex(Hex.new(0, 0))
		gm.occupy(Hex.new(0, 0))
		gm.clear_grid()
		assert_false(gm.is_inside_grid(Hex.new(0, 0)))
		assert_false(gm.is_occupied(Hex.new(0, 0)))


class TestPiecePlacement:
	extends GutTest

	var gm

	func before_each():
		gm = Island.new()
		add_child_autofree(gm)
		gm.create_hex_grid(2)

	func test_data_sceneが設定されていればそのシーンでインスタンス化される():
		var data = PieceData.get_data(PieceData.Type.MINER)
		gm.place_piece(data.shape, Hex.new(0, 0), data)
		var piece = gm.get_piece_at_hex(Hex.new(0, 0))
		assert_null(piece.get_node_or_null("Input"), "MINERはInputノードを持たないはず")

	func test_有効な場所にピースを配置できる():
		var shape = [Hex.new(0, 0), Hex.new(1, 0)]
		var data = PieceData.get_data(PieceData.Type.CHEST)
		gm.place_piece(shape, Hex.new(0, 0), data)

		assert_true(gm.is_occupied(Hex.new(0, 0)))
		assert_true(gm.is_occupied(Hex.new(1, 0)))
		assert_not_null(gm.get_piece_at_hex(Hex.new(0, 0)))

	func test_占有済みまたは範囲外には配置できない():
		var shape = [Hex.new(0, 0)]
		var data = PieceData.get_data(PieceData.Type.CHEST)
		gm.place_piece(shape, Hex.new(0, 0), data)

		assert_false(gm.can_place(shape, Hex.new(0, 0)), "占有済み")
		assert_false(gm.can_place(shape, Hex.new(5, 5)), "範囲外")

	func test_ピースを削除すると占有が解除されノードも解放される():
		var data = PieceData.get_data(PieceData.Type.CHEST)
		gm.place_piece([Hex.new(0, 0)], Hex.new(0, 0), data)
		var piece = gm.get_piece_at_hex(Hex.new(0, 0))

		gm.remove_piece_at(Hex.new(0, 0))

		assert_false(gm.is_occupied(Hex.new(0, 0)))
		assert_true(piece.is_queued_for_deletion())

	func test_配置時にタイルの色がピースの色に更新される():
		var data = PieceData.get_data(PieceData.Type.MINER)
		gm.place_piece([Hex.new(0, 0)], Hex.new(0, 0), data)
		var tile = gm.find_hex_tile(Hex.new(0, 0))
		assert_eq(tile.get_color(), data.color)


class TestNeighbors:
	extends GutTest

	var gm

	func before_each():
		gm = Island.new()
		add_child_autofree(gm)
		gm.create_hex_grid(2)

	func test_指定した方向の隣接ピースを取得できる():
		var data = PieceData.get_data(PieceData.Type.CHEST)
		gm.place_piece([Hex.new(0, 0)], Hex.new(0, 0), data)
		gm.place_piece([Hex.new(0, 0)], Hex.new(1, -1), data)

		var piece_b = gm.get_piece_at_hex(Hex.new(1, -1))
		assert_eq(gm.get_neighbor_piece(Hex.new(0, 0), 1), piece_b)
		assert_null(gm.get_neighbor_piece(Hex.new(0, 0), 3), "存在しない方向はnull")

	func test_出力ポートの先にピースがある場合は搬送先として登録される():
		var port_data = PieceData.new([Hex.new(0, 0)], [{"hex": Hex.new(0, 0), "direction": 0}])
		var chest_data = PieceData.get_data(PieceData.Type.CHEST)
		gm.place_piece([Hex.new(0, 0)], Hex.new(0, 0), port_data)
		gm.place_piece([Hex.new(0, 0)], Hex.new(1, 0), chest_data)

		var source = gm.get_piece_at_hex(Hex.new(0, 0))
		var target = gm.get_piece_at_hex(Hex.new(1, 0))
		assert_true(target in source.output.connected_pieces)

	func test_ポートが向いていない隣接ピースは搬送先に登録されない():
		var port_data = PieceData.new([Hex.new(0, 0)], [{"hex": Hex.new(0, 0), "direction": 0}])
		var chest_data = PieceData.get_data(PieceData.Type.CHEST)
		gm.place_piece([Hex.new(0, 0)], Hex.new(0, 0), port_data)
		gm.place_piece([Hex.new(0, 0)], Hex.new(0, -1), chest_data)

		var source = gm.get_piece_at_hex(Hex.new(0, 0))
		var target = gm.get_piece_at_hex(Hex.new(0, -1))
		assert_false(target in source.output.connected_pieces)

	func test_ピース削除時に周囲の搬送先リストが自動更新される():
		var port_data = PieceData.new([Hex.new(0, 0)], [{"hex": Hex.new(0, 0), "direction": 0}])
		var chest_data = PieceData.get_data(PieceData.Type.CHEST)
		gm.place_piece([Hex.new(0, 0)], Hex.new(0, 0), port_data)
		gm.place_piece([Hex.new(0, 0)], Hex.new(1, 0), chest_data)

		var source = gm.get_piece_at_hex(Hex.new(0, 0))
		gm.remove_piece_at(Hex.new(1, 0))
		assert_eq(source.output.connected_pieces.size(), 0, "削除後は接続が切れているべき")


class TestDetailMode:
	extends GutTest

	var gm

	func before_each():
		gm = Island.new()
		add_child_autofree(gm)
		gm.create_hex_grid(2)

	func test_詳細モード設定が既存および新規ピースに反映される():
		var data = PieceData.get_data(PieceData.Type.CHEST)
		gm.place_piece([Hex.new(0, 0)], Hex.new(0, 0), data)
		var piece_old = gm.get_piece_at_hex(Hex.new(0, 0))

		gm.toggle_detail_mode()
		assert_true(piece_old.is_detail_mode)

		gm.place_piece([Hex.new(0, 0)], Hex.new(1, 0), data)
		var piece_new = gm.get_piece_at_hex(Hex.new(1, 0))
		assert_true(piece_new.is_detail_mode)
