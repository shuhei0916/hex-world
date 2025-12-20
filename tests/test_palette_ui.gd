extends GutTest

const PaletteUIScene = preload("res://scenes/ui/palette/palette_ui.tscn")

var ui: PaletteUI
var palette: Palette

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

func test_スロットにピースのアイコンが表示される():
	# スロット0のUI要素を取得
	# PaletteUIはColorRectを子として追加しているので、最初の子がSlot0のはず
	var slot0 = ui.get_child(0)
	assert_not_null(slot0)
	
	# スロット内にプレビュー用のノードが生成されているか確認
	assert_gt(slot0.get_child_count(), 0, "Slot should contain icon nodes")