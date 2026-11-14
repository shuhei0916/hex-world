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
	assert_string_contains(panel.get_row_text("belt_speed_1"), "Iron Ingot 20")


func test_レベルが足りない研究はボタンが押せず理由が表示される():
	assert_true(panel.get_button("unlock_assembler").disabled)
	assert_eq(panel.get_status_text("unlock_assembler"), "ハブ Lv3 で研究できる")


func test_在庫が足りない研究はボタンが押せない():
	HubGoals.level = 3
	HubGoals.level_up.emit(3, "")
	assert_true(panel.get_button("unlock_assembler").disabled)
	assert_eq(panel.get_status_text("unlock_assembler"), "在庫不足")


func test_在庫が貯まると開いたままでもボタンが押せるようになる():
	HubGoals.level = 3
	HubGoals.add_stock("iron_ingot", 10)
	assert_false(panel.get_button("unlock_assembler").disabled)
	assert_eq(panel.get_status_text("unlock_assembler"), "")


func test_ボタンを押すと研究され_研究済みと表示される():
	HubGoals.level = 3
	HubGoals.add_stock("iron_ingot", 10)
	panel.get_button("unlock_assembler").pressed.emit()
	assert_true(HubGoals.is_researched("unlock_assembler"))
	assert_true(panel.get_button("unlock_assembler").disabled)
	assert_eq(panel.get_status_text("unlock_assembler"), "研究済み")


func test_前提の研究を済ませると次の研究の表示が変わる():
	HubGoals.level = 5
	HubGoals.add_stock("iron_ingot", 20)
	assert_eq(panel.get_status_text("belt_speed_2"), "先に「コンベア高速化 I」が必要")
	panel.get_button("belt_speed_1").pressed.emit()
	assert_eq(panel.get_status_text("belt_speed_2"), "在庫不足")


func test_やり直しで進行度が消えると表示も元に戻る():
	HubGoals.level = 3
	HubGoals.add_stock("iron_ingot", 10)
	panel.get_button("unlock_assembler").pressed.emit()
	HubGoals.reset()
	assert_eq(panel.get_status_text("unlock_assembler"), "ハブ Lv3 で研究できる")
