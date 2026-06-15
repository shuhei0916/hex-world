extends GutTest

const PieceInfoPanelScene = preload("res://scenes/ui/hud/piece_info_panel.tscn")

var panel: PieceInfoPanel


func before_each():
	panel = PieceInfoPanelScene.instantiate()
	add_child_autofree(panel)


func test_show_infoでNameLabelにピース名が入る():
	panel.show_info("Miner", "鉱床から鉱石を採掘する")
	assert_eq(panel.name_label.text, "Miner")


func test_show_infoでDescriptionLabelに説明文が入る():
	panel.show_info("Miner", "鉱床から鉱石を採掘する")
	assert_eq(panel.description_label.text, "鉱床から鉱石を採掘する")


func test_show_infoでパネルが表示される():
	panel.visible = false
	panel.show_info("Miner", "鉱床から鉱石を採掘する")
	assert_true(panel.visible)


func test_clearでパネルが非表示になる():
	panel.visible = true
	panel.clear()
	assert_false(panel.visible)


func test_show_infoでRateLabelに生産速度が入る():
	panel.show_info("Miner", "鉱床から鉱石を採掘する", "60.0/m")
	assert_eq(panel.rate_label.text, "60.0/m")


func test_show_infoで速度が空文字ならRateLabelが非表示():
	panel.show_info("Conveyor", "アイテムを運ぶ", "")
	assert_false(panel.rate_label.visible)
