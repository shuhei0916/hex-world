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
