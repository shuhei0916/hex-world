extends GutTest

const MainScene = preload("res://scenes/main/main.tscn")
const Island = preload("res://scenes/components/island/island.gd")

var main: Main


func before_each():
	main = MainScene.instantiate()
	add_child_autofree(main)


func after_each():
	await get_tree().process_frame


func test_MainはIslandを持つ():
	assert_not_null(main.island)
	assert_true(main.island is Island)


func test_グリッド更新シグナルでIslandに登録される():
	var gm = main.island
	if gm == null:
		fail_test("Island not found")
		return

	gm.clear_grid()

	gm.create_hex_grid(2)
	assert_true(gm.is_inside_grid(Hex.new(0, 0)), "Center hex should be registered")


func test_MainはHUDを持つ():
	assert_not_null(main.hud, "HUD node should be linked in Main")


func test_MainのHUDはHUD型である():
	assert_true(main.hud is HUD)


func test_HUDのスロット選択でPiecePlacerが更新される():
	var btn = main.hud.toolbar.get_child(0) as Button
	btn.button_pressed = true
	main.hud.on_slot_pressed(0)
	assert_not_null(main.piece_placer.selected_scene)
