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

func test_クリックでPlayerに移動指示が送られる():
	scene_instance._ready()
	add_child(scene_instance)
	
	# テスト用のマウスクリックイベントを作成
	var click_event = InputEventMouseButton.new()
	click_event.button_index = MOUSE_BUTTON_LEFT
	click_event.pressed = true
	click_event.position = Vector2(100, 50)  # グリッド上の任意の位置
	
	# Playerにmove_to_hexメソッドがあることを前提とする
	var player = scene_instance.get_node("Player")
	var initial_target = player.get("target_hex_position")
	
	# クリックイベントを送信
	scene_instance._input(click_event)
	
	# 移動指示が設定されたことを確認
	var new_target = player.get("target_hex_position")
	assert_not_null(new_target)

func test_マウス座標変換が一貫して正確に行われる():
	scene_instance._ready()
	add_child(scene_instance)
	
	# GridDisplayのレイアウトから既知のhex座標のピクセル座標を取得
	var grid_display = scene_instance.grid_display
	if grid_display and grid_display.layout:
		# 原点に近いhex座標を使用（より確実な変換のため）
		var target_hex = Hex.new(1, 0)
		var expected_pixel_position = Layout.hex_to_pixel(grid_display.layout, target_hex)
		
		# そのピクセル座標を使用してhex座標に逆変換
		var actual_hex = scene_instance.get_hex_at_mouse_position(expected_pixel_position)
		
		# 逆変換が正確であることを確認
		var distance_to_expected = Hex.distance(actual_hex, target_hex)
		assert_true(distance_to_expected == 0, "座標変換の精度が期待値から外れています: 期待 %s 実際 %s" % [target_hex, actual_hex])