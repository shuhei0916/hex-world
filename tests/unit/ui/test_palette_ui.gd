extends GutTest

const PaletteUIScene = preload("res://scenes/ui/palette/palette_ui.tscn")

var ui: PaletteUI
var piece_placer: PiecePlacer


func before_each():
	ui = PaletteUIScene.instantiate()
	piece_placer = PiecePlacer.new()
	add_child_autofree(ui)
	add_child_autofree(piece_placer)

	ui.setup(piece_placer)


func test_パレットUIは9つのスロットを生成する():
	assert_eq(ui.get_slot_count(), 9)


func test_アクティブスロット変更でUIハイライトが更新される():
	assert_eq(ui.get_active_index(), -1)

	# UIを直接操作
	ui.select_slot(3)

	# UIが反応しているか確認
	assert_eq(ui.get_active_index(), 3)
	assert_not_null(piece_placer.selected_piece_data, "PiecePlacerにデータがセットされているべき")


func test_スロットにピースのアイコンが表示される():
	# HBoxContainerの子要素としてスロットが存在する
	var slot0 = ui.hbox_container.get_child(0)
	assert_not_null(slot0)

	# スロット内にIconRootが生成されているか確認
	assert_gt(slot0.get_child_count(), 0, "Slot should contain icon nodes")


func test_スロットをクリックするとパレットの選択が更新される():
	# スロット2をクリックしたふりをする
	var slot2 = ui.slot_rects[2]
	var event = InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = true
	event.position = Vector2(1, 1)

	slot2.gui_input.emit(event)

	# UIの選択状態が更新されているか確認
	assert_eq(ui.get_active_index(), 2, "スロット2をクリックしたらインデックス2が選択されるべき")
	assert_not_null(piece_placer.selected_piece_data)
