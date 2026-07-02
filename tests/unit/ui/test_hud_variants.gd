extends GutTest

const HUDScene = preload("res://scenes/ui/hud/hud.tscn")
const MINER_SCENE = preload("res://scenes/components/piece/miner_t2.tscn")
const SMELTER_SCENE = preload("res://scenes/components/piece/smelter_t2.tscn")

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


func test_バリアントが1つのスロットではcycle_variantを呼んでも変化しない():
	_select_slot(0)
	var before = hud.get_scene_for_slot(0)
	hud.cycle_variant()
	assert_eq(hud.get_scene_for_slot(0), before)


func test_cycle_variantでバリアントが循環しslot_selectedが再発火する():
	hud._slot_variants[2] = [SMELTER_SCENE, MINER_SCENE]
	hud._variant_indices[2] = 0
	_select_slot(2)

	watch_signals(hud)
	hud.cycle_variant()

	assert_eq(hud.get_scene_for_slot(2), MINER_SCENE)
	assert_signal_emitted_with_parameters(hud, "slot_selected", [MINER_SCENE])


func test_スロット切り替え時にバリアントインデックスが0にリセットされる():
	# スロット2でバリアントをt2（インデックス1）に進める
	hud._slot_variants[2] = [SMELTER_SCENE, MINER_SCENE]
	_select_slot(2)
	hud.cycle_variant()
	assert_eq(hud._variant_indices[2], 1)

	# 別スロット（スロット1）に切り替えると、スロット2のインデックスがリセットされる
	_select_slot(1)
	assert_eq(hud._variant_indices[2], 0)


func test_最後のバリアントの次はインデックス0に戻る():
	hud._slot_variants[2] = [SMELTER_SCENE, MINER_SCENE]
	hud._variant_indices[2] = 1
	_select_slot(2)

	hud.cycle_variant()

	assert_eq(hud.get_scene_for_slot(2), SMELTER_SCENE)
