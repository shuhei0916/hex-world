extends GutTest

const PieceInfoPanelScene = preload("res://scenes/ui/hud/piece_info_panel.tscn")

var panel: PieceInfoPanel


func before_each():
	panel = PieceInfoPanelScene.instantiate()
	add_child_autofree(panel)


func test_show_infoでNameLabelにピース名が入る():
	panel.show_info("Miner", "鉱床から鉱石を採掘する")
	assert_eq(panel.name_label.text, "Miner")
