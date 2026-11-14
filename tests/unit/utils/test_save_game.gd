# gdlint:disable=duplicated-load
extends GutTest

const WorldScript = preload("res://scenes/components/world/world.gd")
const HubGoalsScript = preload("res://scenes/utils/hub_goals.gd")
const CONVEYOR = preload("res://scenes/components/piece/conveyor.tscn")
const MINER = preload("res://scenes/components/piece/miner_t1.tscn")
const SENDER = preload("res://scenes/components/piece/sender.tscn")
const RECEIVER = preload("res://scenes/components/piece/receiver.tscn")
const TEST_PATH := "user://test_save_game.json"

var world: World
var goals: Node


func before_each():
	world = _new_world()
	goals = _new_goals()
	DirAccess.remove_absolute(TEST_PATH)


func after_each():
	DirAccess.remove_absolute(TEST_PATH)


func _new_world() -> World:
	var w = WorldScript.new()
	add_child_autofree(w)
	return w


func _new_goals() -> Node:
	var g = HubGoalsScript.new()
	add_child_autofree(g)
	return g


# 保存→JSON文字列化→復元までを通す（JSON を経ると整数が小数になるため、必ず経由して確かめる）
func _roundtrip() -> World:
	var data = SaveGame.capture(world, goals)
	var restored_data = JSON.parse_string(JSON.stringify(data))
	var restored = _new_world()
	goals = _new_goals()
	SaveGame.apply(restored, restored_data, goals)
	return restored


class TestPlanetAndChunks:
	extends "res://tests/unit/utils/test_save_game.gd"

	func before_each():
		super()
		world.setup_planet(Planet.new(3, 77))
		world.set_active_chunk(Hex.new(0, 0))

	func test_惑星の半径とシードが復元され同じバイオーム配置になる():
		var restored = _roundtrip()
		var hex = Hex.new(2, -1)
		assert_eq(restored.get_planet().radius, 3)
		assert_eq(restored.get_planet().get_biome_id(hex), world.get_planet().get_biome_id(hex))

	func test_アクティブなchunkが復元される():
		world.set_active_chunk(Hex.new(1, 0))
		var restored = _roundtrip()
		assert_true(Hex.equals(restored.get_active_hex(), Hex.new(1, 0)))

	func test_訪れたchunkだけが復元される():
		world.set_active_chunk(Hex.new(1, 0))
		var restored = _roundtrip()
		assert_eq(restored.get_chunk_hexes().size(), 2)
		assert_null(restored.get_chunk(Hex.new(2, 0)))

	func test_鉱床の位置と種類が復元される():
		var chunk = world.get_active_chunk()
		var restored_chunk = _roundtrip().get_active_chunk()
		var mismatches = 0
		var deposits = 0
		for hex in chunk.get_all_hexes():
			if chunk.get_hex_resource(hex) != "":
				deposits += 1
			if chunk.get_hex_resource(hex) != restored_chunk.get_hex_resource(hex):
				mismatches += 1
		assert_gt(deposits, 0, "前提: 鉱床がある")
		assert_eq(mismatches, 0)


class TestPieces:
	extends "res://tests/unit/utils/test_save_game.gd"

	var chunk: Chunk

	func before_each():
		super()
		chunk = world.create_chunk(Hex.new(0, 0))
		world.set_active_chunk(Hex.new(0, 0))

	func test_ピースの種類と位置と向きが復元される():
		chunk.place_piece(CONVEYOR, Hex.new(2, 1), 4)
		var piece = _roundtrip().get_active_chunk().get_piece_at_hex(Hex.new(2, 1))
		assert_not_null(piece)
		assert_eq(piece.piece_type, PieceData.Type.CONVEYOR)
		assert_eq(piece.rotation_state, 4)

	func test_ピースの数が一致する():
		chunk.place_piece(CONVEYOR, Hex.new(2, 1))
		chunk.place_piece(CONVEYOR, Hex.new(3, 1))
		chunk.place_piece(MINER, Hex.new(-2, 0))
		assert_eq(_roundtrip().get_active_chunk().get_piece_count(), 3)

	func test_コンベアの入力方向が復元される():
		chunk.place_piece(CONVEYOR, Hex.new(2, 1), 0, 5)
		var piece = _roundtrip().get_active_chunk().get_piece_at_hex(Hex.new(2, 1))
		assert_eq(piece.input_direction, 5)

	func test_コンベア同士の接続が復元される():
		chunk.place_piece(CONVEYOR, Hex.new(1, 1))
		chunk.place_piece(CONVEYOR, Hex.new(2, 1))
		var restored_chunk = _roundtrip().get_active_chunk()
		var first = restored_chunk.get_piece_at_hex(Hex.new(1, 1))
		var second = restored_chunk.get_piece_at_hex(Hex.new(2, 1))
		assert_eq(first.get_connected_pieces(), [second])

	func test_鉱床の上のMinerは復元後も同じ資源を採掘する():
		chunk.mark_resource_hex(Hex.new(-2, 0), "coal")
		chunk.place_piece(MINER, Hex.new(-2, 0))
		var miner = _roundtrip().get_active_chunk().get_piece_at_hex(Hex.new(-2, 0))
		assert_eq(miner.current_recipe.outputs, {"coal": 1})

	func test_chunkをまたぐSenderとReceiverの接続が復元される():
		var east = world.create_chunk(Hex.new(1, 0))
		chunk.create_hex_grid(2)
		east.create_hex_grid(2)
		chunk.place_piece(SENDER, Hex.new(1, 1, -2))
		east.place_piece(RECEIVER, Hex.new(-1, -1, 2))
		var data = JSON.parse_string(JSON.stringify(SaveGame.capture(world, goals)))
		var restored = _new_world()
		SaveGame.apply(restored, data, _new_goals())
		var sender = restored.get_chunk(Hex.new(0, 0)).get_piece_at_hex(Hex.new(1, 1, -2))
		var receiver = restored.get_chunk(Hex.new(1, 0)).get_piece_at_hex(Hex.new(-1, -1, 2))
		assert_not_null(receiver)
		assert_eq(sender.get_connected_pieces(), [receiver])

	func test_chunkの大きさが復元される():
		chunk.create_hex_grid(2)
		assert_eq(_roundtrip().get_active_chunk().grid_radius, 2)


class TestHubProgress:
	extends "res://tests/unit/utils/test_save_game.gd"

	var chunk: Chunk

	func before_each():
		super()
		chunk = world.create_chunk(Hex.new(0, 0))
		world.set_active_chunk(Hex.new(0, 0))

	func test_ハブのレベルと解放済みの報酬が復元される():
		goals.advance_level()
		goals.advance_level()
		_roundtrip()
		assert_eq(goals.level, 3)
		assert_true(goals.is_reward_unlocked("unlock_smelter"))
		assert_false(goals.is_reward_unlocked("unlock_mixer"))

	func test_研究済みの研究とその効果が復元される():
		goals.level = 3
		goals.add_stock("iron_ingot", 100)
		goals.research("unlock_assembler")
		goals.research("belt_speed_1")
		_roundtrip()
		assert_true(goals.is_researched("belt_speed_1"))
		assert_true(goals.is_reward_unlocked("unlock_assembler"))
		assert_eq(goals.get_belt_speed(), 1.5)
		assert_false(goals.is_researched("mining_speed_1"))

	func test_在庫が復元される():
		goals.add_stock("iron_ore", 12)
		goals.add_stock("coal", 3)
		_roundtrip()
		assert_eq(goals.get_stock("iron_ore"), 12)
		assert_eq(goals.get_stock("coal"), 3)

	func test_ハブは復元後のレベルの目標を表示し納品数も引き継ぐ():
		goals.advance_level()
		chunk.place_hub("iron_ingot", 20)
		chunk.get_piece_at_hex(Hex.new(0, 0)).get_node("Hub").add_received(7)
		var hub = _roundtrip().get_active_chunk().get_piece_at_hex(Hex.new(0, 0)).get_node("Hub")
		assert_eq(hub.goal_item, "iron_ingot")
		assert_eq(hub.goal_count, 20)
		assert_eq(hub.received_count, 7)


class TestFile:
	extends "res://tests/unit/utils/test_save_game.gd"

	func test_保存前はセーブデータが存在しない():
		assert_false(SaveGame.exists(TEST_PATH))

	func test_書き出したデータを読み戻せる():
		SaveGame.write(TEST_PATH, {"version": 1, "chunks": []})
		assert_true(SaveGame.exists(TEST_PATH))
		assert_eq(SaveGame.read(TEST_PATH)["chunks"], [])

	func test_削除するとセーブデータが無くなる():
		SaveGame.write(TEST_PATH, {"version": 1})
		SaveGame.delete(TEST_PATH)
		assert_false(SaveGame.exists(TEST_PATH))

	func test_壊れたファイルは空のデータとして扱う():
		var file = FileAccess.open(TEST_PATH, FileAccess.WRITE)
		file.store_string("{ これは JSON ではない")
		file.close()
		assert_eq(SaveGame.read(TEST_PATH), {})

	func test_存在しないファイルは空のデータとして扱う():
		assert_eq(SaveGame.read(TEST_PATH), {})


class TestChestSave:
	extends "res://tests/unit/utils/test_save_game.gd"

	const CHEST_OUT = preload("res://scenes/components/piece/chest_out.tscn")

	var chunk: Chunk

	func before_each():
		super()
		chunk = world.create_chunk(Hex.new(0, 0))
		world.set_active_chunk(Hex.new(0, 0))

	func test_chunkの共有倉庫の中身が復元される():
		chunk.storage.add("iron_ore", 12)
		chunk.storage.add("coal", 3)
		var restored = _roundtrip().get_active_chunk()
		assert_eq(restored.storage.get_count("iron_ore"), 12)
		assert_eq(restored.storage.get_count("coal"), 3)

	func test_搬出チェストで選んだアイテムが復元される():
		chunk.place_piece(CHEST_OUT, Hex.new(2, 0))
		chunk.get_piece_at_hex(Hex.new(2, 0)).get_node("ChestOutput").select_item("coal")
		var restored = _roundtrip().get_active_chunk().get_piece_at_hex(Hex.new(2, 0))
		assert_eq(restored.get_node("ChestOutput").selected_item, "coal")

	func test_復元した搬出チェストは復元した共有倉庫から取り出す():
		chunk.storage.add("coal", 3)
		chunk.place_piece(CHEST_OUT, Hex.new(2, 0))
		chunk.get_piece_at_hex(Hex.new(2, 0)).get_node("ChestOutput").select_item("coal")
		var restored_chunk = _roundtrip().get_active_chunk()
		var chest = restored_chunk.get_piece_at_hex(Hex.new(2, 0))
		chest.tick(0.1)
		assert_eq(restored_chunk.storage.get_count("coal"), 2)
		assert_eq(chest.get_item_count("coal"), 1)
