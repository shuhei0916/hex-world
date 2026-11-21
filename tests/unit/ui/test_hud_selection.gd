# 設置するピースを選ぶ・解除する操作。どの経路で選んでも・解除しても、後片付けが同じになることを確かめる
extends GutTest

const HUDScene = preload("res://scenes/ui/hud/hud.tscn")

var hud: HUD
var _window_size: Vector2i


# ヘッドレスのウィンドウは小さく、画面下のツールバーが画面外に出るので、実際のマウス操作の間だけ広げる
func before_all():
	_window_size = get_window().size
	get_window().size = Vector2i(1280, 720)


func after_all():
	get_window().size = _window_size


func before_each():
	HubGoals.reset()
	hud = HUDScene.instantiate()
	add_child_autofree(hud)


func after_each():
	HubGoals.reset()


# Container のレイアウトが決まるまで待つ（ボタンの画面上の位置を使うテスト用）
func _settle_layout() -> void:
	await get_tree().process_frame
	await get_tree().process_frame


func _mouse_button(btn: Control, button_index: MouseButton, pressed: bool) -> InputEventMouseButton:
	var ev := InputEventMouseButton.new()
	ev.button_index = button_index
	ev.pressed = pressed
	ev.position = btn.get_global_rect().get_center()
	ev.global_position = ev.position
	return ev


# 実際のマウスでボタンをクリックする（押して離す）
func _click(btn: Control, button_index := MOUSE_BUTTON_LEFT) -> void:
	get_viewport().push_input(_mouse_button(btn, button_index, true))
	get_viewport().push_input(_mouse_button(btn, button_index, false))


func _move_mouse_to(btn: Control) -> void:
	var ev := InputEventMouseMotion.new()
	ev.position = btn.get_global_rect().get_center()
	ev.global_position = ev.position
	get_viewport().push_input(ev)


func _pressed_slots() -> Array:
	var result := []
	for i in hud.slot_buttons.size():
		if hud.slot_buttons[i].button_pressed:
			result.append(i)
	return result


# --- 選ぶ ---


func test_ボタンをクリックするとピースが選ばれる():
	hud.select_slot(0)
	hud.deselect()
	await _settle_layout()
	watch_signals(hud)
	_click(hud.slot_buttons[6])
	assert_eq(hud.get_active_index(), 6)
	assert_signal_emitted_with_parameters(hud, "slot_selected", [hud.get_scene_for_slot(6)])


func test_別のピースを選ぶと押された見た目も移る():
	hud.select_slot(0)
	hud.select_slot(6)
	assert_eq(_pressed_slots(), [6])


func test_未解放のピースは状態を直接解放してもすぐ選べる():
	# 解放の判定はボタンの見た目ではなくゲームの状態で行う
	HubGoals.creative_mode = true
	hud.select_slot(2)
	assert_eq(hud.get_active_index(), 2)


# --- 解除する（どの経路でも同じ後片付け） ---


func _assert_cleared(message: String) -> void:
	assert_eq(hud.get_active_index(), -1, message)
	assert_eq(_pressed_slots(), [], message + ": 押された見た目も消える")
	assert_false(hud.variant_panel.visible, message + ": 切替パネルも消える")
	assert_false(hud.info_panel.visible, message + ": 説明も消える")


func test_deselectで解除すると切替パネルも消える():
	hud.select_slot(1)  # Miner は T1/T2 の切替パネルが出る
	assert_true(hud.variant_panel.visible, "前提")
	hud.deselect()
	_assert_cleared("deselect")


func test_同じスロットをもう一度選ぶと解除され切替パネルも消える():
	hud.select_slot(1)
	watch_signals(hud)
	hud.select_slot(1)
	_assert_cleared("もう一度選ぶ")
	assert_signal_emitted_with_parameters(hud, "slot_selected", [null])


func test_選んでいるボタンをもう一度クリックすると解除され切替パネルも消える():
	hud.select_slot(1)
	await _settle_layout()
	_click(hud.slot_buttons[1])
	_assert_cleared("もう一度クリック")


func test_同じ数字キーをもう一度押すと解除される():
	hud.select_slot(1)
	var ev := InputEventKey.new()
	ev.keycode = KEY_2
	ev.pressed = true
	get_viewport().push_input(ev)
	_assert_cleared("もう一度キー")


func test_ジャンルを切り替えて解除しても切替パネルは消える():
	hud.select_slot(1)
	hud.category_buttons[0].pressed.emit()
	_assert_cleared("ジャンルの切り替え")


func test_ツールバーの上で右クリックすると選択が解除される():
	hud.select_slot(1)
	await _settle_layout()
	_click(hud.slot_buttons[1], MOUSE_BUTTON_RIGHT)
	_assert_cleared("ツールバーで右クリック")


func test_何も選んでいないときの解除でも選択なしが通知される():
	watch_signals(hud)
	hud.deselect()
	assert_signal_emitted_with_parameters(hud, "slot_selected", [null])


# --- ツールバーにマウスが乗った ---


func test_ツールバーのボタンにマウスが乗ると通知される():
	hud.category_buttons[0].pressed.emit()
	await _settle_layout()
	watch_signals(hud)
	_move_mouse_to(hud.slot_buttons[0])
	await get_tree().process_frame
	assert_signal_emitted(hud, "toolbar_hovered")
