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


func test_バリアントが2つ以上のスロット選択時バリアントボタン行が表示される():
	# スロット1はMiner（t1/t2の2バリアント）
	HubGoals.gained_rewards["unlock_miner"] = true
	hud._refresh_unlock_states()
	_select_slot(1)
	assert_true(hud.info_panel.variant_row.visible)
