extends GutTest

const DebugOverlay = preload("res://scenes/ui/debug_overlay/debug_overlay.gd")


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
