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

func test_DebugLabelノードがシーンに存在する():
	var scene_instance = MainScene.instantiate()
	var debug_label = scene_instance.get_node("DebugLabel")
	assert_not_null(debug_label)
	assert_true(debug_label is Label)
	scene_instance.queue_free()

func test_update_debug_displayメソッドが存在する():
	var scene_instance = MainScene.instantiate()
	assert_true(scene_instance.has_method("update_debug_display"))
	scene_instance.queue_free()

func test_デバッグモード変数が初期化されている():
	var scene_instance = MainScene.instantiate()
	assert_true(scene_instance.has_method("get") and scene_instance.get("debug_mode") != null)
	assert_false(scene_instance.debug_mode)  # 初期状態はfalse
	scene_instance.queue_free()

func test_toggle_debug_modeメソッドが存在する():
	var scene_instance = MainScene.instantiate()
	assert_true(scene_instance.has_method("toggle_debug_mode"))
	scene_instance.queue_free()

func test_デバッグモードをトグルできる():
	var scene_instance = MainScene.instantiate()
	
	# 初期状態はfalse
	assert_false(scene_instance.debug_mode)
	
	# トグル実行
	scene_instance.toggle_debug_mode()
	assert_true(scene_instance.debug_mode)
	
	# 再度トグル
	scene_instance.toggle_debug_mode()
	assert_false(scene_instance.debug_mode)
	
	scene_instance.queue_free()

func test_デバッグモードONでhexタイルに座標オーバーレイが表示される():
	var scene_instance = MainScene.instantiate()
	add_child(scene_instance)  # シーンツリーに追加して@onreadyを実行
	
	# setup_gameが自動実行されるので、hex_tileが作成されていることを確認
	var grid_display = scene_instance.get_node("GridDisplay")
	assert_true(grid_display.get_child_count() > 0)
	
	# デバッグモードをONにする
	scene_instance.debug_mode = true
	scene_instance.update_hex_overlay_display()
	
	# hex_tileにLabelが追加されていることを確認
	var first_hex_tile = grid_display.get_child(0)
	var coord_label = first_hex_tile.get_node_or_null("CoordLabel")
	assert_not_null(coord_label)
	assert_true(coord_label.visible)
	
	scene_instance.queue_free()

func test_デバッグモードOFFでhexタイルの座標オーバーレイが非表示になる():
	var scene_instance = MainScene.instantiate()
	add_child(scene_instance)  # シーンツリーに追加して@onreadyを実行
	
	# setup_gameが自動実行されるので、hex_tileが作成されていることを確認
	var grid_display = scene_instance.get_node("GridDisplay")
	assert_true(grid_display.get_child_count() > 0)
	
	# 一度ONにしてからOFFにする
	scene_instance.debug_mode = true
	scene_instance.update_hex_overlay_display()
	scene_instance.debug_mode = false
	scene_instance.update_hex_overlay_display()
	
	# hex_tileのLabelが非表示になっていることを確認
	var first_hex_tile = grid_display.get_child(0)
	var coord_label = first_hex_tile.get_node_or_null("CoordLabel")
	assert_not_null(coord_label)  # Labelは存在する
	assert_false(coord_label.visible)  # しかし非表示
	
	scene_instance.queue_free()