# gdlint:disable=constant-name
extends GutTest

const SMELTER_SCENE = preload("res://scenes/components/piece/smelter.tscn")

# 機械の受け入れ口は Crafter（入力スロットを内包）。setup でレシピが入り入力容量が定まる。
var input


func before_each():
	var piece = SMELTER_SCENE.instantiate()
	add_child_autofree(piece)
	piece.setup()
	input = piece.get_node("Crafter")


func test_満杯でないInputはcan_accept_itemがtrueを返す():
	assert_true(input.can_accept_item("iron_ore"))


func test_満杯のInputはcan_accept_itemがfalseを返す():
	input.add_item("iron_ore", input.input_capacity)
	assert_false(input.can_accept_item("iron_ore"))
