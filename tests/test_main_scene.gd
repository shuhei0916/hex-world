extends GutTest

# MainScene - 動作するドキュメント
# ゲームのメインシーンとして、hex座標変換・デバッグ機能を提供する
class_name TestMainScene

const MainScene = preload("res://scenes/MainScene.tscn")
var scene_instance: Node2D

func before_each():
	scene_instance = MainScene.instantiate()

func after_each():
	scene_instance.queue_free()

func test_原点のマウス座標は中央hexに変換される():
	var mouse_pos = Vector2(0.0, 0.0)
	var hex_coord = scene_instance.get_hex_at_mouse_position(mouse_pos)
	
	assert_eq(hex_coord.q, 0)
	assert_eq(hex_coord.r, 0)

func test_デバッグモードは初期状態でOFFである():
	assert_false(scene_instance.debug_mode)

func test_デバッグモードはトグルで切り替えられる():
	scene_instance.toggle_debug_mode()
	assert_true(scene_instance.debug_mode)
	
	scene_instance.toggle_debug_mode()
	assert_false(scene_instance.debug_mode)

func test_デバッグモードONで各hexに座標が表示される():
	add_child(scene_instance)
	
	scene_instance.debug_mode = true
	scene_instance.update_hex_overlay_display()
	
	var grid_display = scene_instance.get_node("GridDisplay")
	var first_hex_tile = grid_display.get_child(0)
	var coord_label = first_hex_tile.get_node_or_null("CoordLabel")
	
	assert_not_null(coord_label)
	assert_true(coord_label.visible)
	assert_true(coord_label.text.begins_with("("))

func test_デバッグモードOFFで座標表示が隠れる():
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

func test_MainSceneにPlayerが追加される():
	scene_instance._ready()
	
	var player = scene_instance.get_node_or_null("Player")
	assert_not_null(player)
	assert_true(player is Player)