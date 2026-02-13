# gdlint:disable=constant-name
extends GutTest

const HEX_TILE_SCENE = preload("res://scenes/components/hex_tile/hex_tile.tscn")


# --- 物流と接続のテスト（結合テスト） ---
class TestPieceLogistics:
	extends GutTest

	var grid_manager: GridManager

	func before_each():
		grid_manager = GridManager.new()
		grid_manager.hex_tile_scene = HEX_TILE_SCENE
		add_child_autofree(grid_manager)
		grid_manager.create_hex_grid(3)

	func test_生産ライン全体の連携が正しく機能する():
		var m_data = PieceData.new(
			[Hex.new(0, 0)], [{"hex": Hex.new(0, 0), "direction": 0}], "miner"
		)
		var s_data = PieceData.new(
			[Hex.new(0, 0)], [{"hex": Hex.new(0, 0), "direction": 0}], "smelter"
		)

		grid_manager.place_piece([Hex.new(0, 0)], Hex.new(0, 0), null, -1, 0, m_data)
		grid_manager.place_piece([Hex.new(0, 0)], Hex.new(1, 0), null, -1, 0, s_data)
		grid_manager.place_piece([Hex.new(0, 0)], Hex.new(2, 0), null, PieceData.Type.CHEST)

		var miner = grid_manager.get_piece_at_hex(Hex.new(0, 0))
		var smelter = grid_manager.get_piece_at_hex(Hex.new(1, 0))
		var chest = grid_manager.get_piece_at_hex(Hex.new(2, 0))

		miner.tick(1.1)
		assert_eq(smelter.get_item_count("iron_ore"), 1, "採掘機から炉へ移動するべき")

		smelter.tick(3.1)
		assert_eq(chest.get_item_count("iron_ingot"), 1, "炉からチェストへ移動するべき")
