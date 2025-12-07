extends GutTest

const PaletteUIScene = preload("res://scenes/ui/palette/palette_ui.tscn")
const Palette = preload("res://scenes/ui/palette/palette.gd")

var ui
var palette

func before_each():
	ui = PaletteUIScene.instantiate()
	palette = Palette.new()
	add_child_autofree(ui)
	add_child_autofree(palette)
	ui.palette = palette

func test_パレットUIは9つのスロットを生成する():
	# _ready() でスロット生成されるはず
	assert_eq(ui.get_slot_count(), 9)

func test_アクティブスロット変更でUIハイライトが更新される():
	assert_eq(ui.get_highlighted_index(), -1)
	
	# パレットモデルを操作
	palette.select_slot(3)
	
	# UIが反応しているか確認
	assert_eq(ui.get_highlighted_index(), 3)
