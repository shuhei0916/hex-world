extends GutTest

# MainScene - 動作するドキュメント
# ゲームのメインシーンとして、hex座標変換・デバッグ機能を提供する
class_name TestMainScene

const MainScene = preload("res://scenes/MainScene.tscn")

func test_原点のマウス座標は中央hexに変換される():
	var scene_instance = MainScene.instantiate()
	var mouse_pos = Vector2(0.0, 0.0)
	
	var hex_coord = scene_instance.get_hex_at_mouse_position(mouse_pos)
	
	assert_eq(hex_coord.q, 0)
	assert_eq(hex_coord.r, 0)
	scene_instance.queue_free()

func test_デバッグモードは初期状態でOFFである():
	var scene_instance = MainScene.instantiate()
	
	assert_false(scene_instance.debug_mode)
	scene_instance.queue_free()

func test_デバッグモードはトグルで切り替えられる():
	var scene_instance = MainScene.instantiate()
	
	scene_instance.toggle_debug_mode()
	assert_true(scene_instance.debug_mode)
	
	scene_instance.toggle_debug_mode()
	assert_false(scene_instance.debug_mode)
	
	scene_instance.queue_free()

func test_デバッグモードONで各hexに座標が表示される():
	var scene_instance = MainScene.instantiate()
	add_child(scene_instance)
	
	scene_instance.debug_mode = true
	scene_instance.update_hex_overlay_display()
	
	var grid_display = scene_instance.get_node("GridDisplay")
	var first_hex_tile = grid_display.get_child(0)
	var coord_label = first_hex_tile.get_node_or_null("CoordLabel")
	
	assert_not_null(coord_label)
	assert_true(coord_label.visible)
	assert_true(coord_label.text.begins_with("("))
	
	scene_instance.queue_free()

func test_デバッグモードOFFで座標表示が隠れる():
	var scene_instance = MainScene.instantiate()
	add_child(scene_instance)
	
	# 一度表示してから隠す
	scene_instance.debug_mode = true
	scene_instance.update_hex_overlay_display()
	scene_instance.debug_mode = false
	scene_instance.update_hex_overlay_display()
	
	var grid_display = scene_instance.get_node("GridDisplay")
	var first_hex_tile = grid_display.get_child(0)
	var coord_label = first_hex_tile.get_node_or_null("CoordLabel")
	
	assert_false(coord_label.visible)
	
	scene_instance.queue_free()