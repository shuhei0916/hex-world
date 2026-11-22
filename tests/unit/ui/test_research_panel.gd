# gdlint:disable=max-public-methods
extends GutTest

## 研究ツリーの画面。研究を六角形のノードで、行=系統・列=ハブのレベルに並べ、前提を線でつなぐ。
## ノードを選ぶと、右の詳細に説明・価格・状態と「研究する」ボタンが出る。

var panel: ResearchPanel


func before_each():
	HubGoals.reset()
	panel = ResearchPanel.new()
	add_child_autofree(panel)


func after_each():
	HubGoals.reset()


# ---- 開閉 --------------------------------------------------------------------


func test_最初は閉じている():
	assert_false(panel.visible)


func test_切り替えると開き_もう一度で閉じる():
	panel.toggle()
	assert_true(panel.visible)
	panel.toggle()
	assert_false(panel.visible)


func test_閉じるボタンで閉じる():
	panel.toggle()
	panel.close_button.pressed.emit()
	assert_false(panel.visible)


func test_開閉すると通知される():
	watch_signals(panel)
	panel.toggle()
	assert_signal_emitted(panel, "visibility_changed")


func test_背景は不透明で後ろのマップが透けない():
	var style = panel.get_theme_stylebox("panel") as StyleBoxFlat
	assert_not_null(style)
	assert_gt(style.bg_color.a, 0.95)


# ---- ツリーの並び ------------------------------------------------------------


func test_すべての研究がノードとして並ぶ():
	for id in Research.all_ids():
		assert_not_null(panel.get_node_button(id), id)


func test_同じ系統の研究は横一列に並ぶ():
	assert_eq(panel.get_node_center("belt_speed_1").y, panel.get_node_center("belt_speed_3").y)
	assert_ne(panel.get_node_center("belt_speed_1").y, panel.get_node_center("mining_speed_1").y)


func test_必要なハブのレベルが高い研究ほど右にある():
	var lv3 = panel.get_node_center("belt_speed_1").x
	var lv5 = panel.get_node_center("belt_speed_2").x
	var lv8 = panel.get_node_center("belt_speed_3").x
	assert_lt(lv3, lv5)
	assert_lt(lv5, lv8)


func test_同じレベルの研究は縦にそろう():
	# どちらも Lv4
	assert_eq(
		panel.get_node_center("unlock_chunk_chest").x, panel.get_node_center("mining_speed_2").x
	)


func test_前提の研究とは線でつながる():
	assert_true(["belt_speed_1", "belt_speed_2"] in panel.get_links())
	assert_true(["unlock_biome_chest", "unlock_planet_chest"] in panel.get_links())
	assert_false(["belt_speed_1", "belt_speed_3"] in panel.get_links(), "前提でなければつながない")


func test_列の見出しにハブのレベル_行の見出しに系統名が出る():
	assert_true("Lv3" in panel.get_column_titles())
	assert_true("Lv10" in panel.get_column_titles())
	assert_eq(panel.get_row_titles(), ["物流", "採掘", "チェスト", "戦闘"])


# ---- ノードの状態 ------------------------------------------------------------


func test_ノードの色は状態で変わる():
	HubGoals.level = 3
	HubGoals.add_stock("iron_ingot", 20)
	var available = panel.get_node_button("belt_speed_1").get_fill_color()
	var locked = panel.get_node_button("unlock_planet_chest").get_fill_color()
	HubGoals.research("belt_speed_1")
	var done = panel.get_node_button("belt_speed_1").get_fill_color()
	assert_ne(available, locked)
	assert_ne(available, done)
	assert_ne(done, locked)


func test_研究済みの前提からの線は明るくなる():
	var before = panel.get_link_color("belt_speed_1", "belt_speed_2")
	HubGoals.level = 3
	HubGoals.add_stock("iron_ingot", 20)
	HubGoals.research("belt_speed_1")
	assert_ne(panel.get_link_color("belt_speed_1", "belt_speed_2"), before)


# ---- 選択と詳細 --------------------------------------------------------------


func test_ノードを押すと選ばれ_詳細に名前と説明と価格が出る():
	panel.get_node_button("belt_speed_1").pressed.emit()
	assert_eq(panel.get_selected(), "belt_speed_1")
	assert_string_contains(panel.get_detail_text(), "コンベア高速化 I")
	assert_string_contains(panel.get_detail_text(), "2倍")
	assert_string_contains(panel.get_detail_text(), "価格: Iron Ingot 0/20")


func test_選んでいるノードは印が付く():
	panel.select("belt_speed_1")
	assert_true(panel.get_node_button("belt_speed_1").selected)
	panel.select("mining_speed_1")
	assert_false(panel.get_node_button("belt_speed_1").selected)


func test_開いたときは研究できるものが選ばれている():
	HubGoals.level = 3
	HubGoals.add_stock("iron_ingot", 20)
	panel.toggle()
	assert_eq(panel.get_selected(), "belt_speed_1")


func test_価格には手持ちの数も表示される():
	HubGoals.add_stock("iron_ingot", 5)
	panel.select("belt_speed_1")
	assert_string_contains(panel.get_detail_text(), "Iron Ingot 5/20")


func test_レベルが足りない研究はボタンが押せず理由が表示される():
	panel.select("belt_speed_1")
	assert_true(panel.research_button.disabled)
	assert_eq(panel.get_status_text(), "ハブ Lv3 で研究できる")


func test_在庫が足りない研究はボタンが押せない():
	HubGoals.level = 3
	HubGoals.level_up.emit(3, "")
	panel.select("belt_speed_1")
	assert_true(panel.research_button.disabled)
	assert_eq(panel.get_status_text(), "在庫不足")


func test_在庫が貯まると開いたままでもボタンが押せるようになる():
	panel.select("belt_speed_1")
	HubGoals.level = 3
	HubGoals.add_stock("iron_ingot", 20)
	assert_false(panel.research_button.disabled)
	assert_eq(panel.get_status_text(), "")


func test_ボタンを押すと選んでいる研究が研究され_研究済みと表示される():
	HubGoals.level = 3
	HubGoals.add_stock("iron_ingot", 20)
	panel.select("belt_speed_1")
	panel.research_button.pressed.emit()
	assert_true(HubGoals.is_researched("belt_speed_1"))
	assert_true(panel.research_button.disabled)
	assert_eq(panel.get_status_text(), "研究済み")


func test_前提の研究を済ませると次の研究の表示が変わる():
	HubGoals.level = 5
	HubGoals.add_stock("iron_ingot", 20)
	panel.select("belt_speed_2")
	assert_eq(panel.get_status_text(), "先に「コンベア高速化 I」が必要")
	HubGoals.research("belt_speed_1")
	assert_eq(panel.get_status_text(), "在庫不足")


func test_やり直しで進行度が消えると表示も元に戻る():
	HubGoals.level = 3
	HubGoals.add_stock("iron_ingot", 20)
	panel.select("belt_speed_1")
	panel.research_button.pressed.emit()
	HubGoals.reset()
	assert_eq(panel.get_status_text(), "ハブ Lv3 で研究できる")
