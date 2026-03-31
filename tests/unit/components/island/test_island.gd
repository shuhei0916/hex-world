# gdlint:disable=constant-name
extends GutTest

const Island = preload("res://scenes/components/island/island.gd")
const CHEST_SCENE = preload("res://scenes/components/piece/chest.tscn")
const MINER_SCENE = preload("res://scenes/components/piece/miner.tscn")
const CONVEYOR_SCENE = preload("res://scenes/components/piece/conveyor.tscn")


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

	func test_MINERシーンを使うとInputノードがない():
		gm.place_piece(MINER_SCENE, Hex.new(0, 0))
		var piece = gm.get_piece_at_hex(Hex.new(0, 0))
		assert_null(piece.get_node_or_null("Input"), "MINERはInputノードを持たないはず")

	func test_有効な場所にピースを配置できる():
		# CONVEYOR shape: (-1,0),(0,0),(1,0),(2,0) relative to base
		gm.place_piece(CONVEYOR_SCENE, Hex.new(0, 0))
		assert_true(gm.is_occupied(Hex.new(0, 0)))
		assert_true(gm.is_occupied(Hex.new(1, 0)))
		assert_not_null(gm.get_piece_at_hex(Hex.new(0, 0)))

	func test_占有済みまたは範囲外には配置できない():
		gm.place_piece(CHEST_SCENE, Hex.new(0, 0))
		var shape: Array[Hex] = [Hex.new(0, 0)]
		assert_false(gm.can_place(shape, Hex.new(0, 0)), "占有済み")
		assert_false(gm.can_place(shape, Hex.new(5, 5)), "範囲外")

	func test_ピースを削除すると占有が解除されノードも解放される():
		gm.place_piece(CHEST_SCENE, Hex.new(0, 0))
		var piece = gm.get_piece_at_hex(Hex.new(0, 0))
		gm.remove_piece_at(Hex.new(0, 0))
		assert_false(gm.is_occupied(Hex.new(0, 0)))
		assert_true(piece.is_queued_for_deletion())

	func test_配置時にピースの色でHexTileが生成される():
		gm.place_piece(MINER_SCENE, Hex.new(0, 0))
		var piece = gm.get_piece_at_hex(Hex.new(0, 0))
		for child in piece.get_children():
			if child is HexTile:
				assert_eq((child as HexTile).get_color(), piece.piece_color)
				return
		fail_test("ピースにHexTileが存在しない")


class TestNeighbors:
	extends GutTest

	var gm

	func before_each():
		gm = Island.new()
		add_child_autofree(gm)
		gm.create_hex_grid(2)

	func test_指定した方向の隣接ピースを取得できる():
		gm.place_piece(CHEST_SCENE, Hex.new(0, 0))
		gm.place_piece(CHEST_SCENE, Hex.new(1, -1))
		var piece_b = gm.get_piece_at_hex(Hex.new(1, -1))
		assert_eq(gm.get_neighbor_piece(Hex.new(0, 0), 1), piece_b)
		assert_null(gm.get_neighbor_piece(Hex.new(0, 0), 3), "存在しない方向はnull")

	func test_出力ポートの先にピースがある場合は搬送先として登録される():
		# CONVEYOR at (-1,0): occupies (-2,0),(-1,0),(0,0),(1,0)
		# port_hex=(2,0) offset → absolute (1,0), direction E → neighbor (2,0)
		gm.place_piece(CONVEYOR_SCENE, Hex.new(-1, 0))
		gm.place_piece(CHEST_SCENE, Hex.new(2, 0))
		var source = gm.get_piece_at_hex(Hex.new(0, 0))
		var target = gm.get_piece_at_hex(Hex.new(2, 0))
		assert_true(target in source.output.connected_pieces)

	func test_ポートが向いていない隣接ピースは搬送先に登録されない():
		gm.place_piece(CONVEYOR_SCENE, Hex.new(-1, 0))
		gm.place_piece(CHEST_SCENE, Hex.new(0, -1))
		var source = gm.get_piece_at_hex(Hex.new(0, 0))
		var target = gm.get_piece_at_hex(Hex.new(0, -1))
		assert_false(target in source.output.connected_pieces)

	func test_ピース削除時に周囲の搬送先リストが自動更新される():
		gm.place_piece(CONVEYOR_SCENE, Hex.new(-1, 0))
		gm.place_piece(CHEST_SCENE, Hex.new(2, 0))
		var source = gm.get_piece_at_hex(Hex.new(0, 0))
		gm.remove_piece_at(Hex.new(2, 0))
		assert_eq(source.output.connected_pieces.size(), 0, "削除後は接続が切れているべき")
