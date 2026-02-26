# gdlint:disable=constant-name
extends GutTest


# --- 物流と接続のテスト（結合テスト） ---
class TestPieceLogistics:
	extends GutTest

	var island: Island

	func before_each():
		island = Island.new()
		add_child_autofree(island)
		island.create_hex_grid(3)

	func test_生産ライン全体の連携が正しく機能する():
		var m_data = PieceData.new(
			[Hex.new(0, 0)], [{"hex": Hex.new(0, 0), "direction": 0}], "miner"
		)
		var s_data = PieceData.new(
			[Hex.new(0, 0)], [{"hex": Hex.new(0, 0), "direction": 0}], "smelter"
		)
		var chest_data = PieceData.get_data(PieceData.Type.CHEST)

		island.place_piece([Hex.new(0, 0)], Hex.new(0, 0), m_data)
		island.place_piece([Hex.new(0, 0)], Hex.new(1, 0), s_data)
		island.place_piece([Hex.new(0, 0)], Hex.new(2, 0), chest_data)

		var miner = island.get_piece_at_hex(Hex.new(0, 0))
		var smelter = island.get_piece_at_hex(Hex.new(1, 0))
		var chest = island.get_piece_at_hex(Hex.new(2, 0))

		miner.tick(1.1)
		assert_eq(smelter.get_item_count("iron_ore"), 1, "採掘機から炉へ移動するべき")

		smelter.tick(3.1)
		assert_eq(chest.get_item_count("iron_ingot"), 1, "炉からチェストへ移動するべき")
