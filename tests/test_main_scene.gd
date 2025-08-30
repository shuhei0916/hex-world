extends GutTest

# MainSceneのテスト
class_name TestMainScene

const MainScene = preload("res://scenes/MainScene.tscn")

func test_MainSceneを読み込みできる():
	var scene_instance = MainScene.instantiate()
	assert_not_null(scene_instance)
	scene_instance.queue_free()

func test_GridDisplayノードがシーンに存在する():
	var scene_instance = MainScene.instantiate()
	var grid_display = scene_instance.get_node("GridDisplay")
	assert_not_null(grid_display)
	scene_instance.queue_free()

func test_Camera2Dノードがシーンに存在する():
	var scene_instance = MainScene.instantiate()
	var camera = scene_instance.get_node("Camera2D")
	assert_not_null(camera)
	scene_instance.queue_free()

func test_シーンの初期化が成功する():
	var scene_instance = MainScene.instantiate()
	
	var grid_display = scene_instance.get_node("GridDisplay")
	assert_not_null(grid_display)
	
	scene_instance.queue_free()