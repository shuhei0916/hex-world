extends GutTest

# スロットの切り替え先（T1/T2・チェストの共有範囲）を T キーで選ぶ

const HUDScene = preload("res://scenes/ui/hud/hud.tscn")
const SMELTER_T1 = preload("res://scenes/components/piece/smelter_t1.tscn")
const SMELTER_T2 = preload("res://scenes/components/piece/smelter_t2.tscn")
const SMELTER_SLOT := 2

var hud: HUD


func before_each():
	HubGoals.gained_rewards.clear()
	hud = HUDScene.instantiate()
	add_child_autofree(hud)
	# スロット3（Smelter）は未解放だと選べないので、ここでは解放しておく
	HubGoals.gained_rewards["unlock_smelter"] = true
	HubGoals.unlocks_changed.emit()


func after_each():
	HubGoals.gained_rewards.clear()


func test_切り替え先が1つのスロットではcycle_variantを呼んでも変化しない():
	hud.select_slot(0)
	var before = hud.get_scene_for_slot(0)
	hud.cycle_variant()
	assert_eq(hud.get_scene_for_slot(0), before)


func test_cycle_variantでT2に切り替わりslot_selectedが再発火する():
	hud.select_slot(SMELTER_SLOT)
	assert_eq(hud.get_scene_for_slot(SMELTER_SLOT), SMELTER_T1, "最初は T1")
	watch_signals(hud)
	hud.cycle_variant()
	assert_eq(hud.get_scene_for_slot(SMELTER_SLOT), SMELTER_T2)
	assert_signal_emitted_with_parameters(hud, "slot_selected", [SMELTER_T2])


func test_別のスロットに移ると切り替え先はT1に戻る():
	hud.select_slot(SMELTER_SLOT)
	hud.cycle_variant()
	hud.select_slot(1)
	assert_eq(hud.get_scene_for_slot(SMELTER_SLOT), SMELTER_T1)


func test_最後の切り替え先の次は最初に戻る():
	hud.select_slot(SMELTER_SLOT)
	hud.cycle_variant()
	hud.cycle_variant()
	assert_eq(hud.get_scene_for_slot(SMELTER_SLOT), SMELTER_T1)
