extends GutTest

## バイオームチェスト: ひと続きの地域（隣り合う同じバイオームの chunk のまとまり）の中で中身を共有する。

const WorldScript = preload("res://scenes/components/world/world.gd")
const HubGoalsScript = preload("res://scenes/utils/hub_goals.gd")
const HUDScene = preload("res://scenes/ui/hud/hud.tscn")
const CHEST_IN = preload("res://scenes/components/piece/chest_in.tscn")
const BIOME_IN = preload("res://scenes/components/piece/biome_chest_in.tscn")
const BIOME_OUT = preload("res://scenes/components/piece/biome_chest_out.tscn")
const PLANET_IN = preload("res://scenes/components/piece/planet_chest_in.tscn")
const CONVEYOR = preload("res://scenes/components/piece/conveyor.tscn")

var world: World
var planet: Planet
# 同じ地域の2つの chunk と、別の地域の chunk
var hex_a: Hex
var hex_b: Hex
var hex_other: Hex


func before_each():
	HubGoals.reset()
	world = WorldScript.new()
	add_child_autofree(world)
	planet = Planet.new(3, 77)
	world.setup_planet(planet)
	_pick_hexes()


func after_each():
	HubGoals.reset()


func _pick_hexes() -> void:
	var hexes = planet.get_chunk_hexes()
	hex_a = hexes[0]
	hex_b = null
	hex_other = null
	for hex in hexes:
		if Hex.equals(hex, hex_a):
			continue
		if planet.get_region_id(hex) == planet.get_region_id(hex_a):
			if hex_b == null:
				hex_b = hex
		elif hex_other == null:
			hex_other = hex


func _chest_in(chunk_hex: Hex, scene: PackedScene = BIOME_IN) -> Piece:
	var chunk = world.create_chunk(chunk_hex)
	chunk.place_piece(scene, Hex.new(4, 0))
	return chunk.get_piece_at_hex(Hex.new(4, 0))


func _storage_of(chest: Piece) -> SharedStorage:
	return chest.get_node("ChestInput").get_storage()


class TestSharing:
	extends "res://tests/unit/components/piece/test_biome_chest.gd"

	func test_前提_同じ地域の2つのchunkと別の地域のchunkがある():
		assert_not_null(hex_b)
		assert_not_null(hex_other)

	func test_同じ地域の別のchunkとは中身を共有する():
		_chest_in(hex_a).add_item("coal", 4)
		assert_eq(_storage_of(_chest_in(hex_b)).get_count("coal"), 4)

	func test_別の地域のchunkとは中身を共有しない():
		_chest_in(hex_a).add_item("coal", 4)
		assert_eq(_storage_of(_chest_in(hex_other)).get_count("coal"), 0)

	func test_同じ種類のバイオームでも離れた別の地域とは共有しない():
		var same_biome_other_region = null
		for hex in planet.get_chunk_hexes():
			if (
				planet.get_biome_id(hex) == planet.get_biome_id(hex_a)
				and planet.get_region_id(hex) != planet.get_region_id(hex_a)
			):
				same_biome_other_region = hex
				break
		if same_biome_other_region == null:
			pass_test("この惑星には同じ種類のバイオームの地域が1つしかない")
			return
		_chest_in(hex_a).add_item("coal", 4)
		assert_eq(_storage_of(_chest_in(same_biome_other_region)).get_count("coal"), 0)

	func test_バイオームチェストの中身はchunkの倉庫とも惑星の倉庫とも別():
		_chest_in(hex_a).add_item("coal", 4)
		assert_eq(world.get_chunk(hex_a).storage.get_count("coal"), 0)
		assert_eq(world.planet_storage.get_count("coal"), 0)

	func test_同じ地域の別のchunkへコンベア無しでアイテムが渡る():
		_chest_in(hex_a).add_item("coal", 4)
		var chunk_b = world.create_chunk(hex_b)
		chunk_b.place_piece(BIOME_OUT, Hex.new(0, 2))
		chunk_b.place_piece(CONVEYOR, Hex.new(1, 2))
		var chest_out = chunk_b.get_piece_at_hex(Hex.new(0, 2))
		chest_out.get_node("ChestOutput").select_item("coal")
		for i in 10:
			chest_out.tick(0.1)
		assert_eq(chunk_b.get_piece_at_hex(Hex.new(1, 2)).get_item_count("coal"), 1)

	func test_ホバー表示でバイオームの倉庫だと分かる():
		assert_string_contains(PieceStatus.describe(_chest_in(hex_a)), "バイオームの倉庫: 空")


class TestDefinitions:
	extends "res://tests/unit/components/piece/test_biome_chest.gd"

	func test_研究はchunkチェスト_バイオームチェスト_planetチェストの順に連なる():
		assert_eq(Research.get_def("unlock_biome_chest")["requires"], ["unlock_chunk_chest"])
		assert_eq(Research.get_def("unlock_planet_chest")["requires"], ["unlock_biome_chest"])

	func test_研究できるレベルは共有範囲が広いほど高い():
		var chunk_level = Research.get_def("unlock_chunk_chest")["level"]
		var biome_level = Research.get_def("unlock_biome_chest")["level"]
		var planet_level = Research.get_def("unlock_planet_chest")["level"]
		assert_gt(biome_level, chunk_level)
		assert_gt(planet_level, biome_level)

	func test_バイオームチェストは研究するまで解放されない():
		assert_false(PieceData.is_unlocked(PieceData.Type.BIOME_CHEST))
		HubGoals.researched = {"unlock_biome_chest": true}
		assert_true(PieceData.is_unlocked(PieceData.Type.BIOME_CHEST))
		assert_true(PieceData.is_unlocked(PieceData.Type.BIOME_CHEST_OUT))

	func test_バイオームチェストの設置にはコストがかかる():
		assert_false(BuildCost.of_scene(BIOME_IN).is_empty())
		assert_false(BuildCost.of_scene(BIOME_OUT).is_empty())
		assert_ne(BuildCost.of_scene(BIOME_IN), BuildCost.of_scene(CHEST_IN))
		assert_ne(BuildCost.of_scene(BIOME_IN), BuildCost.of_scene(PLANET_IN))


class TestToolbar:
	extends "res://tests/unit/components/piece/test_biome_chest.gd"

	var hud: HUD

	func before_each():
		super()
		HubGoals.researched = {"unlock_chunk_chest": true, "unlock_biome_chest": true}
		hud = HUDScene.instantiate()
		add_child_autofree(hud)
		hud.slot_buttons[9].button_pressed = true
		hud.on_slot_pressed(9)

	func test_切り替えボタンは共有範囲の狭い順に並ぶ():
		var texts = hud.variant_panel.button_row.get_children().map(func(b): return b.text)
		assert_eq(texts, ["Chunk", "Biome", "Planet"])

	func test_切り替えるとchunkチェストの次はバイオームチェストになる():
		hud.cycle_variant()
		assert_eq(hud.get_scene_for_slot(9), BIOME_IN)

	func test_未研究のplanetチェストは飛ばしてchunkチェストに戻る():
		hud.cycle_variant()
		hud.cycle_variant()
		assert_eq(hud.get_scene_for_slot(9), CHEST_IN)


class TestSave:
	extends "res://tests/unit/components/piece/test_biome_chest.gd"

	func _roundtrip() -> World:
		var goals = HubGoalsScript.new()
		add_child_autofree(goals)
		var data = JSON.parse_string(JSON.stringify(SaveGame.capture(world, goals)))
		var restored = WorldScript.new()
		add_child_autofree(restored)
		SaveGame.apply(restored, data, goals)
		return restored

	func test_地域の倉庫の中身が復元される():
		_chest_in(hex_a).add_item("coal", 4)
		world.set_active_chunk(hex_a)
		var restored = _roundtrip()
		var chest = restored.get_chunk(hex_a).get_piece_at_hex(Hex.new(4, 0))
		assert_eq(_storage_of(chest).get_count("coal"), 4)

	func test_復元後も同じ地域の別のchunkと共有される():
		_chest_in(hex_a).add_item("coal", 4)
		_chest_in(hex_b)
		world.set_active_chunk(hex_a)
		var restored = _roundtrip()
		var chest_b = restored.get_chunk(hex_b).get_piece_at_hex(Hex.new(4, 0))
		assert_eq(_storage_of(chest_b).get_count("coal"), 4)
