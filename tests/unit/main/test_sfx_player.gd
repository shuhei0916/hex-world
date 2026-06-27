# gdlint:disable=constant-name
extends GutTest

const SFX_PLAYER_SCENE = preload("res://scenes/main/sfx_player.tscn")
const CONVEYOR_SCENE = preload("res://scenes/components/piece/conveyor.tscn")
const SMELTER_SCENE = preload("res://scenes/components/piece/smelter_t2.tscn")

var sfx
var piece


func before_each():
	sfx = SFX_PLAYER_SCENE.instantiate()
	add_child_autofree(sfx)


func after_each():
	if is_instance_valid(piece):
		piece.free()


func test_全プレイヤーの音量が減衰されている():
	var all_attenuated = true
	for player in sfx.get_children():
		if player is AudioStreamPlayer and player.volume_db > -6.0:
			all_attenuated = false
	assert_true(all_attenuated, "各AudioStreamPlayerはvolume_db -6.0以下であるべき")


func test_ピース設置でplace_buildingが再生される():
	piece = SMELTER_SCENE.instantiate()
	sfx.on_piece_placed(piece)
	assert_true(sfx.get_node("PlaceBuilding").playing)


func test_ドラッグパスへのコンベア追加でplace_beltが再生される():
	sfx.on_conveyor_path_extended()
	assert_true(sfx.get_node("PlaceBelt").playing)


func test_コンベアの一括設置イベントでは音を重ねて鳴らさない():
	piece = CONVEYOR_SCENE.instantiate()
	sfx.on_piece_placed(piece)
	assert_false(sfx.get_node("PlaceBelt").playing or sfx.get_node("PlaceBuilding").playing)


func test_ピース削除でdestroy_buildingが再生される():
	sfx.on_piece_removed()
	assert_true(sfx.get_node("DestroyBuilding").playing)


func test_ツールバーでピースを選択するとui_clickが再生される():
	sfx.on_slot_selected(CONVEYOR_SCENE)
	assert_true(sfx.get_node("UiClick").playing)


func test_ツールバー選択解除では音が鳴らない():
	sfx.on_slot_selected(null)
	assert_false(sfx.get_node("UiClick").playing)
