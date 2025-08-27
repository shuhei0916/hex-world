extends GutTest

# MainSceneのテスト
class_name TestMainScene

const MainScene = preload("res://scenes/MainScene.tscn")

func test_main_scene_loads():
	var scene_instance = MainScene.instantiate()
	assert_not_null(scene_instance)
	scene_instance.queue_free()

func test_grid_display_exists_in_scene():
	var scene_instance = MainScene.instantiate()
	var grid_display = scene_instance.get_node("GridDisplay")
	assert_not_null(grid_display)
	scene_instance.queue_free()

func test_camera_exists_in_scene():
	var scene_instance = MainScene.instantiate()
	var camera = scene_instance.get_node("Camera2D")
	assert_not_null(camera)
	scene_instance.queue_free()

func test_scene_initialization():
	var scene_instance = MainScene.instantiate()
	
	# GridDisplayノードが存在するか
	var grid_display = scene_instance.get_node("GridDisplay")
	assert_not_null(grid_display)
	
	scene_instance.queue_free()