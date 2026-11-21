# gdlint:disable=max-public-methods
# ツールバーは2段: 下の段でジャンルを選ぶと、そのジャンルのピースが上の段に出る
extends GutTest

const HUDScene = preload("res://scenes/ui/hud/hud.tscn")

var hud: HUD


func before_each():
	HubGoals.reset()
	hud = HUDScene.instantiate()
	add_child_autofree(hud)


func after_each():
	HubGoals.reset()


func _visible_slots() -> Array:
	var result := []
	for i in hud.slot_buttons.size():
		if hud.slot_buttons[i].is_visible_in_tree():
			result.append(i)
	return result


func _press_key(keycode: Key) -> void:
	var ev := InputEventKey.new()
	ev.keycode = keycode
	ev.pressed = true
	get_viewport().push_input(ev)
	var release := ev.duplicate()
	release.pressed = false
	get_viewport().push_input(release)


func test_ジャンルは物流_採掘_加工_倉庫の4つ():
	assert_eq(hud.category_buttons.size(), 4)
	assert_eq(hud.get_category_name(0), "物流")
	assert_eq(hud.get_category_name(1), "採掘")
	assert_eq(hud.get_category_name(2), "加工")
	assert_eq(hud.get_category_name(3), "倉庫")


func test_最初はどのジャンルも開いておらずピースの段は出ていない():
	assert_eq(hud.get_active_category(), -1)
	assert_eq(_visible_slots(), [])


func test_ジャンルを押すとそのジャンルのピースだけが上の段に出る():
	hud.category_buttons[0].pressed.emit()
	assert_eq(hud.get_active_category(), 0)
	assert_eq(_visible_slots(), [0, 6], "物流はコンベアと橋")


func test_加工のジャンルには機械が並ぶ():
	HubGoals.creative_mode = true
	HubGoals.unlocks_changed.emit()
	hud.category_buttons[2].pressed.emit()
	assert_eq(_visible_slots(), [2, 3, 4, 5, 9])


func test_ジャンルを押しただけではピースは選ばれない():
	watch_signals(hud)
	hud.category_buttons[1].pressed.emit()
	assert_eq(hud.get_active_index(), -1)
	assert_signal_not_emitted(hud, "slot_selected")


func test_開いているジャンルをもう一度押すと段が閉じる():
	hud.category_buttons[0].pressed.emit()
	hud.category_buttons[0].pressed.emit()
	assert_eq(hud.get_active_category(), -1)
	assert_eq(_visible_slots(), [])


func test_ピースの段が開いているときジャンルのボタンは押された見た目になる():
	hud.category_buttons[1].pressed.emit()
	assert_true(hud.category_buttons[1].button_pressed)
	assert_false(hud.category_buttons[0].button_pressed)


func test_ピースを選んだまま別のジャンルに移ると選択は解除される():
	hud.category_buttons[0].pressed.emit()
	hud.select_slot(0)
	watch_signals(hud)
	hud.category_buttons[1].pressed.emit()
	assert_eq(hud.get_active_index(), -1)
	assert_signal_emitted_with_parameters(hud, "slot_selected", [null])


func test_ピースを選んだままジャンルを閉じると選択は解除される():
	hud.category_buttons[0].pressed.emit()
	hud.select_slot(0)
	hud.category_buttons[0].pressed.emit()
	assert_eq(hud.get_active_index(), -1)


func test_select_slotはボタンを押したのと同じくピースを選びジャンルを開く():
	watch_signals(hud)
	hud.select_slot(6)
	assert_eq(hud.get_active_index(), 6)
	assert_eq(hud.get_active_category(), 0)
	assert_eq(_visible_slots(), [0, 6])
	assert_signal_emitted_with_parameters(hud, "slot_selected", [hud.get_scene_for_slot(6)])


func test_未解放のピースはselect_slotでも選べない():
	hud.select_slot(2)
	assert_eq(hud.get_active_index(), -1)


func test_数字キーでジャンルが閉じていてもピースを選べる():
	_press_key(KEY_7)
	assert_eq(hud.get_active_index(), 6, "7 は橋")
	assert_eq(hud.get_active_category(), 0)


func test_キー0は10番目のスロット():
	HubGoals.creative_mode = true
	HubGoals.unlocks_changed.emit()
	_press_key(KEY_0)
	assert_eq(hud.get_active_index(), 9)


func test_HUDを隠している間は数字キーで選ばない():
	hud.visible = false
	_press_key(KEY_1)
	assert_eq(hud.get_active_index(), -1)


func test_選択を解除してもジャンルの段は開いたまま():
	hud.select_slot(0)
	hud.deselect()
	assert_eq(hud.get_active_category(), 0)


func test_中のピースがすべて未解放のジャンルは押せない():
	assert_true(hud.category_buttons[2].disabled, "加工は最初は精錬炉も未解放")
	assert_true(hud.category_buttons[3].disabled, "倉庫は研究するまで使えない")
	assert_false(hud.category_buttons[0].disabled)


func test_ひとつでも解放されるとジャンルを押せるようになる():
	HubGoals.gained_rewards["unlock_smelter"] = true
	HubGoals.unlocks_changed.emit()
	assert_false(hud.category_buttons[2].disabled)


func test_ボタンはすべて六角形():
	for btn in hud.category_buttons:
		assert_is(btn, HexButton)
	for btn in hud.slot_buttons:
		assert_is(btn, HexButton)


func test_ボタンのアイコンはすべて独自に描いたもの():
	for btn in hud.slot_buttons + hud.category_buttons:
		assert_not_null(btn.hex_icon, btn.name)
		if btn.hex_icon:
			assert_string_starts_with(btn.hex_icon.resource_path, "res://assets/pieces/")


func test_スロットにはキーの数字が添えてある():
	assert_eq(hud.slot_buttons[0].hint, "1")
	assert_eq(hud.slot_buttons[9].hint, "0")


func test_ピースの段はジャンルの段の上にある():
	hud.category_buttons[0].pressed.emit()
	await get_tree().process_frame
	await get_tree().process_frame
	var piece_rect: Rect2 = hud.slot_buttons[0].get_global_rect()
	var category_rect: Rect2 = hud.category_buttons[0].get_global_rect()
	assert_lt(piece_rect.end.y, category_rect.position.y + 1.0)
