# gdlint:disable=constant-name
extends GutTest

const SFX_PLAYER_SCENE = preload("res://scenes/main/sfx_player.tscn")
const CONVEYOR_SCENE = preload("res://scenes/components/piece/conveyor.tscn")
const SMELTER_SCENE = preload("res://scenes/components/piece/smelter.tscn")

var sfx
var piece


func before_each():
	sfx = SFX_PLAYER_SCENE.instantiate()
	add_child_autofree(sfx)


func after_each():
	if is_instance_valid(piece):
		piece.free()


func test_ピース設置でplace_buildingが再生される():
	piece = SMELTER_SCENE.instantiate()
	sfx.on_piece_placed(piece)
	assert_true(sfx.get_node("PlaceBuilding").playing)


func test_コンベア設置ではplace_beltが再生される():
	piece = CONVEYOR_SCENE.instantiate()
	sfx.on_piece_placed(piece)
	assert_true(sfx.get_node("PlaceBelt").playing)
