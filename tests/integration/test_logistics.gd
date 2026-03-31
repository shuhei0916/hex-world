# gdlint:disable=constant-name
extends GutTest


# --- 物流と接続のテスト（結合テスト） ---
class TestPieceLogistics:
	extends GutTest

	const MINER_SCENE = preload("res://scenes/components/piece/miner.tscn")
	const SMELTER_SCENE = preload("res://scenes/components/piece/smelter.tscn")
	const CHEST_SCENE = preload("res://scenes/components/piece/chest.tscn")

	var island: Island

	func before_each():
		island = Island.new()
		add_child_autofree(island)
		island.create_hex_grid(3)

	func test_生産ライン全体の連携が正しく機能する():
		# MINER at (0,0): occupies (0,0),(0,1),(1,0),(1,1)
		#   port at offset (0,1) → absolute (0,1), direction SW → neighbor (-1,2)
		# SMELTER at (-1,2): occupies (-3,2),(-2,2),(-1,2),(-1,3)
		#   port at offset (0,0) → absolute (-1,2), direction E → neighbor (0,2)
		# CHEST at (0,2): occupies (0,2)
		island.place_piece(MINER_SCENE, Hex.new(0, 0))
		island.place_piece(SMELTER_SCENE, Hex.new(-1, 2))
		island.place_piece(CHEST_SCENE, Hex.new(0, 2))

		var miner = island.get_piece_at_hex(Hex.new(0, 0))
		var smelter = island.get_piece_at_hex(Hex.new(-1, 2))
		var chest = island.get_piece_at_hex(Hex.new(0, 2))

		miner.tick(1.1)
		assert_eq(smelter.get_item_count("iron_ore"), 1, "採掘機から炉へ移動するべき")

		smelter.tick(3.1)
		assert_eq(chest.get_item_count("iron_ingot"), 1, "炉からチェストへ移動するべき")
