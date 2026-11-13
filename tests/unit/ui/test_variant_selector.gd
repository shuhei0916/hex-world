extends GutTest

const HUDScene = preload("res://scenes/ui/hud/hud.tscn")

var hud: HUD


func before_each():
	HubGoals.gained_rewards.clear()
	hud = HUDScene.instantiate()
	add_child_autofree(hud)


func after_each():
	HubGoals.gained_rewards.clear()


func _select_slot(index: int) -> void:
	var btn = hud.toolbar.get_child(index) as Button
	btn.button_pressed = true
	hud.on_slot_pressed(index)


func test_バリアントが2つ以上のスロット選択時バリアントパネルが表示される():
	HubGoals.gained_rewards["unlock_miner"] = true
	hud._refresh_unlock_states()
	_select_slot(1)
	assert_true(hud.variant_panel.visible)


func test_バリアントが1つのスロット選択時バリアントパネルが非表示になる():
	_select_slot(0)  # Conveyor: バリアント1つ
	assert_false(hud.variant_panel.visible)


func test_選択解除時バリアントパネルが非表示になる():
	HubGoals.gained_rewards["unlock_miner"] = true
	hud._refresh_unlock_states()
	_select_slot(1)
	hud.deselect()
	assert_false(hud.variant_panel.visible)


func test_バリアントボタン数がバリアント数と一致する():
	HubGoals.gained_rewards["unlock_miner"] = true
	hud._refresh_unlock_states()
	_select_slot(1)  # Miner: t1/t2の2バリアント
	assert_eq(hud.variant_panel.button_row.get_child_count(), 2)


func test_現在選択中のバリアントボタンがpressed状態になる():
	HubGoals.gained_rewards["unlock_miner"] = true
	hud._refresh_unlock_states()
	_select_slot(1)
	var first_btn := hud.variant_panel.button_row.get_child(0) as Button
	assert_true(first_btn.button_pressed)


func test_バリアントボタンクリックでバリアントが切り替わりslot_selectedが発火する():
	HubGoals.gained_rewards["unlock_miner"] = true
	hud._refresh_unlock_states()
	_select_slot(1)
	watch_signals(hud)
	hud._select_variant(1, 1)  # t2を選択
	var expected = hud.get_scene_for_slot(1)
	assert_signal_emitted_with_parameters(hud, "slot_selected", [expected])


func test_Tキーで循環するとバリアントボタンの強調が更新される():
	HubGoals.gained_rewards["unlock_miner"] = true
	hud._refresh_unlock_states()
	_select_slot(1)
	hud.cycle_variant()  # t1→t2
	var second_btn := hud.variant_panel.button_row.get_child(1) as Button
	assert_true(second_btn.button_pressed)


func test_切替パネルはピース情報のスピード表示と重ならず下に並ぶ():
	HubGoals.gained_rewards["unlock_miner"] = true
	hud._refresh_unlock_states()
	_select_slot(1)
	# Container のレイアウトはフレーム処理時に確定する
	await get_tree().process_frame
	await get_tree().process_frame
	var rate_rect = hud.info_panel.rate_label.get_global_rect()
	var variant_rect = hud.variant_panel.get_global_rect()
	assert_true(hud.info_panel.rate_label.visible, "スピードが表示されているべき")
	assert_gt(
		variant_rect.position.y,
		rate_rect.end.y,
		"切替パネル(%s)はスピード表示(%s)より下にあるべき" % [variant_rect, rate_rect]
	)
