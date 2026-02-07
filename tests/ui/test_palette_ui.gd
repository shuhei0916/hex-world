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


func test_スロットをクリックするとパレットの選択が更新される():
	# スロット2をクリックしたふりをする
	var slot2 = ui.slot_rects[2]
	var event = InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = true
	event.position = Vector2(1, 1)  # スロット内の適当な位置

	slot2.gui_input.emit(event)

	# パレットの選択状態が更新されているか確認
	assert_eq(palette.get_active_index(), 2, "スロット2をクリックしたらインデックス2が選択されるべき")


func test_選択中のスロットを再度クリックすると選択が解除される():
	# まずスロット2を選択状態にする
	palette.select_slot(2)
	assert_eq(palette.get_active_index(), 2)

	# スロット2をクリックしたふりをする
	var slot2 = ui.slot_rects[2]
	var event = InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = true
	event.position = Vector2(1, 1)

	slot2.gui_input.emit(event)

	# 選択が解除されているか確認
	assert_eq(palette.get_active_index(), -1, "選択中のスロットを再度クリックしたら非選択になるべき")
