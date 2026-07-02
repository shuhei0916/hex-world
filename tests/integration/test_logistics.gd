# gdlint:disable=constant-name
extends GutTest


# --- 物流と接続のテスト（結合テスト） ---
class TestPieceLogistics:
	extends GutTest

	const MINER_SCENE = preload("res://scenes/components/piece/miner_t2.tscn")
	const SMELTER_SCENE = preload("res://scenes/components/piece/smelter_t2.tscn")
	const CONVEYOR_SCENE = preload("res://scenes/components/piece/conveyor.tscn")

	var chunk: Chunk

	func before_each():
		chunk = Chunk.new()
		add_child_autofree(chunk)
		chunk.create_hex_grid(3)

	func test_生産ライン全体の連携が正しく機能する():
		# MINER at (0,0): occupies (0,0),(0,1),(1,0),(1,1)
		#   port at offset (0,1) → absolute (0,1), direction SW → neighbor (-1,2)
		# SMELTER at (-1,2): occupies (-3,2),(-2,2),(-1,2),(-1,3)
		#   port at offset (0,0) → absolute (-1,2), direction E → neighbor (0,2)
		# CONVEYOR at (0,2): シンクとして受領
		chunk.mark_resource_hex(Hex.new(0, 0), "iron_ore")
		chunk.place_piece(MINER_SCENE, Hex.new(0, 0))
		chunk.place_piece(SMELTER_SCENE, Hex.new(-1, 2))
		chunk.place_piece(CONVEYOR_SCENE, Hex.new(0, 2))

		var miner = chunk.get_piece_at_hex(Hex.new(0, 0))
		var smelter = chunk.get_piece_at_hex(Hex.new(-1, 2))
		var chest = chunk.get_piece_at_hex(Hex.new(0, 2))

		miner.tick(1.1)
		assert_eq(smelter.get_item_count("iron_ore"), 1, "採掘機から炉へ移動するべき")

		smelter.tick(3.1)
		assert_eq(chest.get_item_count("iron_ingot"), 1, "炉からチェストへ移動するべき")
