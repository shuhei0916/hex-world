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

func test_マウス座標からhex座標に変換できる():
	var scene_instance = MainScene.instantiate()
	
	# モックマウス座標（原点付近）
	var mouse_pos = Vector2(0.0, 0.0)
	
	# MainSceneにget_hex_at_mouse_positionメソッドが存在することを確認
	assert_true(scene_instance.has_method("get_hex_at_mouse_position"))
	
	# マウス座標をhex座標に変換
	var hex_coord = scene_instance.get_hex_at_mouse_position(mouse_pos)
	
	# hex座標が返されることを確認（原点なので(0,0)になる）
	assert_not_null(hex_coord)
	assert_eq(hex_coord.q, 0)
	assert_eq(hex_coord.r, 0)
	
	scene_instance.queue_free()