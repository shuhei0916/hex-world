extends GutTest

const PaletteUIScene = preload("res://scenes/PaletteUI.tscn")
const Palette = preload("res://scripts/palette.gd")

func test_パレットUIは9つのスロットを生成する():
	var ui = PaletteUIScene.instantiate()
	var palette = Palette.new()
	ui.palette = palette
	
	add_child(ui)
	# _ready() でスロット生成されるはず
	
	assert_eq(ui.get_slot_count(), 9)
	ui.free()

func test_アクティブスロット変更でUIハイライトが更新される():
	var ui = PaletteUIScene.instantiate()
	var palette = Palette.new()
	ui.palette = palette
	
	add_child(ui)
	
	assert_eq(ui.get_highlighted_index(), 0)
	
	# パレットモデルを操作
	palette.select_slot(3)
	
	# UIが反応しているか確認
	assert_eq(ui.get_highlighted_index(), 3)
	ui.free()
