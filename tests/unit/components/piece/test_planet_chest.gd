extends GutTest

## planet チェスト: 惑星のどの chunk に置いても中身を共有する。

const WorldScript = preload("res://scenes/components/world/world.gd")
const HUDScene = preload("res://scenes/ui/hud/hud.tscn")
const CHEST_IN = preload("res://scenes/components/piece/chest_in.tscn")
const CHEST_OUT = preload("res://scenes/components/piece/chest_out.tscn")
const PLANET_IN = preload("res://scenes/components/piece/planet_chest_in.tscn")
const PLANET_OUT = preload("res://scenes/components/piece/planet_chest_out.tscn")
const CONVEYOR = preload("res://scenes/components/piece/conveyor.tscn")

var world: World
var chunk_a: Chunk
var chunk_b: Chunk


func before_each():
	HubGoals.reset()
	world = WorldScript.new()
	add_child_autofree(world)
	chunk_a = world.create_chunk(Hex.new(0, 0))
	chunk_b = world.create_chunk(Hex.new(1, 0))


func after_each():
	HubGoals.reset()


func _place(chunk: Chunk, scene: PackedScene, hex: Hex) -> Piece:
	chunk.place_piece(scene, hex)
	return chunk.get_piece_at_hex(hex)


class TestSharing:
	extends "res://tests/unit/components/piece/test_planet_chest.gd"

	func test_あるchunkのplanetチェストに入れたアイテムは別のchunkから取り出せる():
		_place(chunk_a, PLANET_IN, Hex.new(0, 0)).add_item("copper_ore", 3)
		var chest_out = _place(chunk_b, PLANET_OUT, Hex.new(0, 0))
		var conveyor = _place(chunk_b, CONVEYOR, Hex.new(1, 0))
		chest_out.get_node("ChestOutput").select_item("copper_ore")
		for i in 10:
			chest_out.tick(0.1)
		assert_eq(conveyor.get_item_count("copper_ore"), 1)

	func test_planetチェストの中身は惑星の共有倉庫に入る():
		_place(chunk_a, PLANET_IN, Hex.new(0, 0)).add_item("copper_ore", 3)
		assert_eq(world.planet_storage.get_count("copper_ore"), 3)

	func test_planetチェストの中身はchunkチェストの倉庫とは別():
		_place(chunk_a, PLANET_IN, Hex.new(0, 0)).add_item("copper_ore", 3)
		assert_eq(chunk_a.storage.get_count("copper_ore"), 0)

	func test_chunkチェストの中身は別のchunkと共有されない():
		_place(chunk_a, CHEST_IN, Hex.new(0, 0)).add_item("copper_ore", 3)
		assert_eq(chunk_b.storage.get_count("copper_ore"), 0)
		assert_eq(world.planet_storage.get_count("copper_ore"), 0)

	func test_あとから訪れたchunkのplanetチェストも同じ倉庫につながる():
		_place(chunk_a, PLANET_IN, Hex.new(0, 0)).add_item("copper_ore", 3)
		var chunk_c = world.create_chunk(Hex.new(-1, 0))
		var chest = _place(chunk_c, PLANET_IN, Hex.new(0, 0))
		assert_eq(chest.get_node("ChestInput").get_storage().get_count("copper_ore"), 3)


class TestDefinitions:
	extends "res://tests/unit/components/piece/test_planet_chest.gd"

	func test_planetチェストはchunkチェストより高い():
		var chunk_cost = BuildCost.of_scene(CHEST_IN)
		var planet_cost = BuildCost.of_scene(PLANET_IN)
		assert_false(planet_cost.is_empty())
		assert_ne(planet_cost, chunk_cost)
		assert_false(BuildCost.of_scene(PLANET_OUT).is_empty())

	func test_planetチェストの研究にはバイオームチェストの研究が前提():
		var def = Research.get_def("unlock_planet_chest")
		assert_true("unlock_biome_chest" in def["requires"])
		assert_gt(def["level"], Research.get_def("unlock_chunk_chest")["level"])

	func test_planetチェストは研究するまで解放されない():
		assert_false(PieceData.is_unlocked(PieceData.Type.PLANET_CHEST))
		HubGoals.researched = {"unlock_chunk_chest": true}
		assert_false(PieceData.is_unlocked(PieceData.Type.PLANET_CHEST))
		HubGoals.researched = {"unlock_chunk_chest": true, "unlock_planet_chest": true}
		assert_true(PieceData.is_unlocked(PieceData.Type.PLANET_CHEST))
		assert_true(PieceData.is_unlocked(PieceData.Type.PLANET_CHEST_OUT))

	func test_ホバー表示でどの範囲の倉庫かが分かる():
		var planet_chest = _place(chunk_a, PLANET_IN, Hex.new(0, 0))
		var chunk_chest = _place(chunk_a, CHEST_IN, Hex.new(2, 0))
		assert_string_contains(PieceStatus.describe(planet_chest), "惑星の倉庫: 空")
		assert_string_contains(PieceStatus.describe(chunk_chest), "chunk の倉庫: 空")


class TestToolbarVariants:
	extends "res://tests/unit/components/piece/test_planet_chest.gd"

	const SLOT_IN := HUD.CHEST_SLOTS[0]
	const SLOT_OUT := HUD.CHEST_SLOTS[1]

	var hud: HUD

	func before_each():
		super()
		HubGoals.researched = {"unlock_chunk_chest": true}
		hud = HUDScene.instantiate()
		add_child_autofree(hud)

	func _select(slot: int) -> void:
		hud.slot_buttons[slot].button_pressed = true
		hud.on_slot_pressed(slot)

	func test_planetチェストを研究していないと切り替えてもchunkチェストのまま():
		_select(SLOT_IN)
		hud.cycle_variant()
		assert_eq(hud.get_scene_for_slot(SLOT_IN), CHEST_IN)

	func test_planetチェストを研究すると切り替えで選べる():
		HubGoals.researched["unlock_planet_chest"] = true
		_select(SLOT_IN)
		hud.cycle_variant()
		assert_eq(hud.get_scene_for_slot(SLOT_IN), PLANET_IN)
		hud.cycle_variant()
		assert_eq(hud.get_scene_for_slot(SLOT_IN), CHEST_IN)

	func test_搬出スロットでもplanetチェストに切り替えられる():
		HubGoals.researched["unlock_planet_chest"] = true
		_select(SLOT_OUT)
		hud.cycle_variant()
		assert_eq(hud.get_scene_for_slot(SLOT_OUT), PLANET_OUT)

	func test_切り替えボタンにはチェストの共有範囲の名前が出る():
		HubGoals.researched["unlock_planet_chest"] = true
		_select(SLOT_IN)
		var texts = hud.variant_panel.button_row.get_children().map(func(b): return b.text)
		assert_eq(texts, ["Chunk", "Biome", "Planet"])

	func test_未研究の切り替え先はボタンが押せない():
		_select(SLOT_IN)
		var buttons = hud.variant_panel.button_row.get_children()
		assert_false(buttons[0].disabled)
		assert_true(buttons[1].disabled)

	func test_機械のスロットの切り替えボタンは従来どおりT1とT2():
		HubGoals.creative_mode = true
		_select(2)
		var texts = hud.variant_panel.button_row.get_children().map(func(b): return b.text)
		assert_eq(texts, ["T1", "T2"])
