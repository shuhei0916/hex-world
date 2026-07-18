# gdlint:disable=constant-name
extends GutTest

const DebugOverlay = preload("res://scenes/ui/debug_overlay/debug_overlay.gd")
const ChunkScript = preload("res://scenes/components/chunk/chunk.gd")


class TestToggle:
	extends GutTest

	var overlay: CanvasLayer

	func before_each():
		overlay = DebugOverlay.new()
		add_child_autofree(overlay)

	func test_toggle_は呼ぶたびにvisibleが反転する():
		var initial = overlay.visible
		overlay.toggle()
		assert_ne(overlay.visible, initial)
		overlay.toggle()
		assert_eq(overlay.visible, initial)


class TestRefresh:
	extends GutTest

	var overlay: CanvasLayer
	var chunk

	func before_each():
		overlay = DebugOverlay.new()
		add_child_autofree(overlay)
		chunk = ChunkScript.new()
		add_child_autofree(chunk)
		chunk.create_hex_grid(2)

	func test_refresh後にチャンクの全ヘックス分のラベルが生成される():
		overlay.refresh(chunk)
		assert_eq(overlay.get_label_count(), chunk.get_grid_hex_count())

	func test_refresh_world_map後にチャンク数分の座標ラベルが生成される():
		var world = load("res://scenes/components/world/world.gd").new()
		add_child_autofree(world)
		world.create_chunk(Hex.new(0, 0))
		world.create_chunk(Hex.new(1, 0))
		var view = WorldMapView.new()
		add_child_autofree(view)
		view.setup(world)
		overlay.refresh_world_map(view, world.get_chunk_hexes())
		assert_eq(overlay.get_label_count(), 2)

	func test_ピース配置済みヘックスのラベルにはピース名が含まれる():
		var conveyor_scene = load("res://scenes/components/piece/conveyor.tscn")
		chunk.place_piece(conveyor_scene, Hex.new(0, 0))
		overlay.refresh(chunk)
		var label_text = overlay.get_label_text_at(Hex.new(0, 0))
		assert_true(
			label_text.contains("Conveyor") or label_text.contains("conveyor"),
			"Expected piece name in label, got: %s" % label_text
		)
