extends GutTest

const HUDScene = preload("res://scenes/ui/hud/hud.tscn")

var hud: HUD
var piece_placer: PiecePlacer


func before_each():
	hud = HUDScene.instantiate()
	piece_placer = PiecePlacer.new()
	add_child_autofree(hud)
	add_child_autofree(piece_placer)

	hud.setup(piece_placer)


func test_HUDは9つのパレットスロットを持つ():
	assert_eq(hud.get_slot_count(), 9)


func test_アクティブスロット変更でUIハイライトが更新される():
	assert_eq(hud.get_active_index(), -1)

	# HUDを直接操作
	hud.select_slot(3)

	# 状態が更新されているか確認
	assert_eq(hud.get_active_index(), 3)
	assert_not_null(piece_placer.selected_piece_data, "PiecePlacerにデータがセットされているべき")


func test_スロットにピースのアイコンが表示される():
	# PaletteContainerの子要素としてスロットが存在する
	var slot0 = hud.palette_container.get_child(0)
	assert_not_null(slot0)

	# スロット内にIconRootが生成されているか確認
	assert_gt(slot0.get_child_count(), 0, "Slot should contain icon nodes")


func test_スロットをクリックすると選択が更新される():
	# スロット2をクリックしたふりをする
	var slot2 = hud.slot_rects[2]
	var event = InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = true
	event.position = Vector2(1, 1)

	slot2.gui_input.emit(event)

	assert_eq(hud.get_active_index(), 2, "スロット2をクリックしたらインデックス2が選択されるべき")
	assert_not_null(piece_placer.selected_piece_data)
