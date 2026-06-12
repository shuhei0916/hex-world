# gdlint:disable=constant-name
extends GutTest

const SMELTER_SCENE = preload("res://scenes/components/piece/smelter.tscn")

var input


func before_each():
	var piece = SMELTER_SCENE.instantiate()
	add_child_autofree(piece)
	input = piece.get_node("Input")


func test_満杯でないInputはcan_accept_itemがtrueを返す():
	assert_true(input.can_accept_item("iron_ore"))
