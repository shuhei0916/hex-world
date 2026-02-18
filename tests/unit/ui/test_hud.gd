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

	# HUDを直接操作（ボタンを真にしてハンドラを呼ぶ）
	var btn3 = hud.toolbar.get_child(3) as Button
	btn3.button_pressed = true
	hud.on_slot_pressed(3)

	# 状態が更新されているか確認
	assert_eq(hud.get_active_index(), 3)
	assert_not_null(piece_placer.selected_piece_data, "PiecePlacerにデータがセットされているべき")


func test_スロットにピースのアイコンが表示される():
	var slot0 = hud.toolbar.get_child(0)
	assert_not_null(slot0)
	assert_gt(slot0.get_child_count(), 0, "Slot should contain icon nodes")


func test_スロットをクリックすると選択が更新される():
	var btn2 = hud.toolbar.get_child(2) as Button
	btn2.button_pressed = true
	hud.on_slot_pressed(2)

	assert_eq(hud.get_active_index(), 2, "スロット2を選択したらインデックス2がアクティブになるべき")
	assert_not_null(piece_placer.selected_piece_data)


func test_右クリックで自律的に選択が解除される():
	# まず選択状態にする
	var btn = hud.slot_buttons[0]
	btn.button_pressed = true
	hud.on_slot_pressed(0)
	assert_eq(hud.get_active_index(), 0)

	# 右クリックイベントをシミュレート
	var event = InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_RIGHT
	event.pressed = true
	hud._unhandled_input(event)

	# 解除されていることを確認
	assert_eq(hud.get_active_index(), -1, "右クリックで選択が解除されるべき")
	assert_null(piece_placer.selected_piece_data, "PiecePlacerの選択も解除されるべき")
