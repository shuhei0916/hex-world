extends GutTest

class_name TestPlayer

class TestPlayerBasics:
	extends GutTest
	
	const PlayerScene = preload("res://scenes/Player.tscn")
	var player: Player
	
	func before_each():
		player = PlayerScene.instantiate()
	
	func after_each():
		player.queue_free()
	
	func test_Playerクラスが正しく初期化される():
		assert_not_null(player)
		assert_true(player is CharacterBody2D)
	
	func test_Playerは初期位置でhex座標00に配置される():
		assert_eq(player.current_hex_position.q, 0)
		assert_eq(player.current_hex_position.r, 0)
	
	func test_Playerはicon_svgスプライトを持つ():
		var sprite = player.get_node_or_null("Sprite2D")
		assert_not_null(sprite)
		assert_not_null(sprite.texture)

class TestPlayerMovement:
	extends GutTest
	
	const PlayerScene = preload("res://scenes/Player.tscn")
	var player: Player
	
	func before_each():
		player = PlayerScene.instantiate()
	
	func after_each():
		player.queue_free()
	
	func test_move_to_hexで移動経路が設定される():
		var target_hex = Hex.new(2, 1)
		player.move_to_hex(target_hex)
		
		assert_not_null(player.movement_path)
		assert_true(player.movement_path.size() > 0)
		
		var final_destination = player.movement_path[-1]
		assert_eq(final_destination.q, 2)
		assert_eq(final_destination.r, 1)
	
	func test_移動経路があるときis_movingがtrueになる():
		var target_hex = Hex.new(1, 0)
		player.move_to_hex(target_hex)
		
		assert_true(player.is_moving)
	
	func test_GridDisplayのレイアウトを使用してhexからピクセル座標に変換できる():
		var layout = Layout.new(
			Layout.layout_pointy,
			Vector2(30, 30),
			Vector2(0, 0)
		)
		
		player.grid_layout = layout
		
		var hex_coord = Hex.new(1, 0)
		var pixel_pos = player.hex_to_pixel_position(hex_coord)
		
		assert_not_null(pixel_pos)
		assert_true(pixel_pos is Vector2)

	func test_移動経路ハイライト用のシグナルが存在する():
		# Playerクラスが移動経路をハイライト要求するシグナルを持つことを確認
		assert_true(player.has_signal("path_highlight_requested"))
		assert_true(player.has_signal("path_highlight_cleared"))

	func test_move_to_hex実行時にpath_highlight_requestedシグナルが発火される():
		# シグナル発火を監視
		watch_signals(player)
		
		# 移動指示を実行
		var target_hex = Hex.new(2, 1)
		player.move_to_hex(target_hex)
		
		# path_highlight_requestedシグナルが発火されたことを確認
		assert_signal_emitted(player, "path_highlight_requested")
		
		# シグナルパラメータに移動経路が含まれることを確認
		var signal_args = get_signal_parameters(player, "path_highlight_requested")
		assert_not_null(signal_args)
		assert_true(signal_args.size() > 0)
		assert_true(signal_args[0] is Array)

class TestPlayerHexPositioning:
	extends GutTest
	
	const Player = preload("res://scripts/player.gd")
	
	var player: Player
	var grid_layout: Layout
	
	func before_each():
		var orientation = Layout.layout_pointy
		var size = Vector2(36.37306, 36.37306)
		var origin = Vector2(0, 0)
		grid_layout = Layout.new(orientation, size, origin)
		
		player = Player.new()
		add_child(player)
	
	func after_each():
		if player:
			player.queue_free()
			remove_child(player)
		player = null
		grid_layout = null
	
	func test_Playerは初期化時にhex座標00の中央に配置される():
		player.setup_grid_layout(grid_layout)
		
		var expected_center = Layout.hex_to_pixel(grid_layout, Hex.new(0, 0))
		
		assert_eq(player.global_position, expected_center)
		assert_true(Hex.equals(player.current_hex_position, Hex.new(0, 0)))
	
	func test_setup_grid_layoutでグリッドレイアウトが設定される():
		assert_null(player.grid_layout)
		
		player.setup_grid_layout(grid_layout)
		
		assert_not_null(player.grid_layout)
		assert_eq(player.grid_layout, grid_layout)

	func test_各hexステップでの中央位置補正が動作する():
		player.setup_grid_layout(grid_layout)
		
		# 移動経路の各ステップでhexの中央に配置されることを検証
		var hex_steps = [Hex.new(0, 0), Hex.new(1, 0), Hex.new(1, -1), Hex.new(2, -1)]
		
		for hex_step in hex_steps:
			# current_hex_positionを設定し、中央位置に補正
			player.current_hex_position = hex_step
			player.update_position_to_hex_center()
			
			# 期待される中央位置を計算
			var expected_center = Layout.hex_to_pixel(grid_layout, hex_step)
			
			# プレイヤーがhexの中央に正確に配置されていることを確認
			assert_eq(player.global_position, expected_center)

	func test_移動完了時にhexの中央に配置される():
		player.setup_grid_layout(grid_layout)
		
		# 目標hex座標への移動を開始
		var target_hex = Hex.new(2, -1)
		player.move_to_hex(target_hex)
		
		# 移動が完了するまでprocess_movementを実行
		# プレイヤーが目標位置に到達し、移動状態が完了することを確認
		var max_iterations = 1000  # 無限ループ防止
		var iterations = 0
		
		while player.is_moving and iterations < max_iterations:
			# 移動を1フレーム進行（delta=0.016は約60FPSを想定）
			player.process_movement(0.016)
			iterations += 1
		
		# 移動完了を確認
		assert_false(player.is_moving)
		
		# 最終位置が目標hexの中央に正確に配置されていることを確認
		var expected_final_position = Layout.hex_to_pixel(grid_layout, target_hex)
		assert_eq(player.global_position, expected_final_position)
		
		# current_hex_positionも更新されていることを確認
		assert_true(Hex.equals(player.current_hex_position, target_hex))