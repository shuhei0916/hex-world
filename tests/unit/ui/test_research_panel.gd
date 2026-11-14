extends GutTest

var panel: ResearchPanel


func before_each():
	HubGoals.reset()
	panel = ResearchPanel.new()
	add_child_autofree(panel)


func after_each():
	HubGoals.reset()


func test_最初は閉じている():
	assert_false(panel.visible)


func test_切り替えると開き_もう一度で閉じる():
	panel.toggle()
	assert_true(panel.visible)
	panel.toggle()
	assert_false(panel.visible)


func test_すべての研究が一覧に並ぶ():
	for id in Research.all_ids():
		assert_not_null(panel.get_button(id), id)


func test_研究の名前と説明と価格が表示される():
	assert_string_contains(panel.get_row_text("belt_speed_1"), "コンベア高速化 I")
	assert_string_contains(panel.get_row_text("belt_speed_1"), "1.5倍")
	assert_string_contains(panel.get_row_text("belt_speed_1"), "価格: Iron Ingot 0/20")


func test_レベルが足りない研究はボタンが押せず理由が表示される():
	assert_true(panel.get_button("belt_speed_1").disabled)
	assert_eq(panel.get_status_text("belt_speed_1"), "ハブ Lv3 で研究できる")


func test_在庫が足りない研究はボタンが押せない():
	HubGoals.level = 3
	HubGoals.level_up.emit(3, "")
	assert_true(panel.get_button("belt_speed_1").disabled)
	assert_eq(panel.get_status_text("belt_speed_1"), "在庫不足")


func test_在庫が貯まると開いたままでもボタンが押せるようになる():
	HubGoals.level = 3
	HubGoals.add_stock("iron_ingot", 20)
	assert_false(panel.get_button("belt_speed_1").disabled)
	assert_eq(panel.get_status_text("belt_speed_1"), "")


func test_ボタンを押すと研究され_研究済みと表示される():
	HubGoals.level = 3
	HubGoals.add_stock("iron_ingot", 20)
	panel.get_button("belt_speed_1").pressed.emit()
	assert_true(HubGoals.is_researched("belt_speed_1"))
	assert_true(panel.get_button("belt_speed_1").disabled)
	assert_eq(panel.get_status_text("belt_speed_1"), "研究済み")


func test_前提の研究を済ませると次の研究の表示が変わる():
	HubGoals.level = 5
	HubGoals.add_stock("iron_ingot", 20)
	assert_eq(panel.get_status_text("belt_speed_2"), "先に「コンベア高速化 I」が必要")
	panel.get_button("belt_speed_1").pressed.emit()
	assert_eq(panel.get_status_text("belt_speed_2"), "在庫不足")


func test_やり直しで進行度が消えると表示も元に戻る():
	HubGoals.level = 3
	HubGoals.add_stock("iron_ingot", 20)
	panel.get_button("belt_speed_1").pressed.emit()
	HubGoals.reset()
	assert_eq(panel.get_status_text("belt_speed_1"), "ハブ Lv3 で研究できる")


func test_閉じるボタンで閉じる():
	panel.toggle()
	panel.close_button.pressed.emit()
	assert_false(panel.visible)


func test_開閉すると通知される():
	watch_signals(panel)
	panel.toggle()
	assert_signal_emitted(panel, "visibility_changed")


func test_価格には手持ちの数も表示される():
	HubGoals.add_stock("iron_ingot", 5)
	assert_string_contains(panel.get_row_text("belt_speed_1"), "Iron Ingot 5/20")


func test_研究できるものが一覧の先頭に来る():
	HubGoals.level = 3
	HubGoals.add_stock("iron_ingot", 20)
	# 鉄インゴットで研究できるのはコンベア高速化だけ。採掘高速化は在庫不足なのでその次
	assert_eq(panel.get_row_order()[0], "belt_speed_1")
	assert_eq(panel.get_row_order()[1], "mining_speed_1")


func test_研究済みのものは一覧の末尾へ回る():
	HubGoals.level = 3
	HubGoals.add_stock("iron_ingot", 20)
	panel.get_button("belt_speed_1").pressed.emit()
	assert_eq(panel.get_row_order()[-1], "belt_speed_1")


func test_研究済みの行は薄く表示される():
	HubGoals.level = 3
	HubGoals.add_stock("iron_ingot", 20)
	panel.get_button("belt_speed_1").pressed.emit()
	assert_lt(panel.get_row("belt_speed_1").modulate.a, 1.0)
	assert_eq(panel.get_row("mining_speed_1").modulate.a, 1.0)


func test_背景は不透明で後ろのマップが透けない():
	var style = panel.get_theme_stylebox("panel") as StyleBoxFlat
	assert_not_null(style)
	assert_gt(style.bg_color.a, 0.95)
