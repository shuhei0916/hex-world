extends GutTest

const PaletteUIScene = preload("res://scenes/PaletteUI.tscn")

func test_パレットUIは9つのスロットを生成する():
	var ui = PaletteUIScene.instantiate()
	add_child(ui)
	ui._ready()
	assert_eq(ui.get_slot_count(), 9)
	ui.free()

func test_アクティブスロット変更でUIハイライトが更新される():
	var ui = PaletteUIScene.instantiate()
	add_child(ui)
	ui._ready()
	assert_eq(ui.get_highlighted_index(), 0)
	ui.palette.handle_number_key_input(KEY_4)
	assert_eq(ui.get_highlighted_index(), 3)
	ui.free()
