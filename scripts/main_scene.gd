extends Node2D

# MainScene - メインゲームシーン制御
# HexFRVRゲームのメインシーン管理

@onready var grid_display = $GridDisplay
var debug_mode: bool = false

func _ready():
	print("MainScene initialized")
	setup_game()

func _process(_delta):
	update_debug_display()

func _input(event):
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_F2:
			toggle_debug_mode()
	elif event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			var mouse_pos = get_global_mouse_position() # NOTE: 本来はevent.positionを変換して使うべき
			handle_mouse_click(mouse_pos)
	elif event is InputEventMouseMotion:
		var mouse_pos = get_global_mouse_position()
		handle_mouse_hover(mouse_pos)

func setup_game():
	# グリッド設定（Unity版のような中規模グリッド）
	if grid_display:
		grid_display.create_hex_grid(4)  # 半径4の六角形グリッド
		grid_display.register_grid_with_manager()
		print("Grid created with %d hexes" % grid_display.get_grid_hex_count())
		
		# グリッドを視覚的に描画
		grid_display.draw_grid()
		print("Grid drawing completed with %d visual tiles" % grid_display.get_child_count())
		
		# Playerにグリッドレイアウトを設定し、初期位置を設定
		var player = get_node_or_null("Player")
		if player and player.has_method("setup_grid_layout") and grid_display.layout:
			player.setup_grid_layout(grid_display.layout)
			print("Player初期位置を hex(0,0) の中央に設定")
			
			# Playerのパスハイライトシグナルを接続
			setup_path_highlight_signals(player)

# マウス座標からhex座標を取得
func get_hex_at_mouse_position(mouse_position: Vector2) -> Hex:
	if grid_display:
		return Layout.pixel_to_hex_rounded(grid_display.layout, mouse_position)
	else:
		# フォールバック: グリッドがない場合は原点のhexを返す
		return Hex.new(0, 0)

# デバッグ表示を更新
func update_debug_display():
	var debug_label = get_node("DebugLabel")
	if debug_label:
		var mouse_pos = get_global_mouse_position()
		var hex_coord = get_hex_at_mouse_position(mouse_pos)
		debug_label.text = "Hex: (%2d, %2d)" % [hex_coord.q, hex_coord.r]

# デバッグモードをトグル
func toggle_debug_mode():
	debug_mode = !debug_mode
	print("Debug mode: %s" % ("ON" if debug_mode else "OFF"))
	update_hex_overlay_display()

# hexタイルの座標オーバーレイ表示を更新
func update_hex_overlay_display():
	if not grid_display:
		return
	
	# 全てのhex_tileに対してCoordLabelの表示を切り替え
	for hex_tile in grid_display.get_children():
		if hex_tile.has_method("setup_hex"):  # HexTileインスタンスの確認
			var coord_label = hex_tile.get_node_or_null("CoordLabel")
			
			if debug_mode:
				# デバッグモードON: Labelを作成または表示
				if not coord_label:
					coord_label = Label.new()
					coord_label.name = "CoordLabel"
					coord_label.add_theme_font_size_override("font_size", 12)
					coord_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
					coord_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
					hex_tile.add_child(coord_label)
				
				# hex座標をテキストとして設定
				if hex_tile.hex_coordinate:
					coord_label.text = "(%d,%d)" % [hex_tile.hex_coordinate.q, hex_tile.hex_coordinate.r]
				coord_label.visible = true
			else:
				# デバッグモードOFF: Labelを非表示
				if coord_label:
					coord_label.visible = false

# マウスクリック処理
func handle_mouse_click(click_position: Vector2):
	# Playerの移動状態をチェック
	var player = get_node_or_null("Player")
	if player and player.is_moving:
		print("Player is currently moving. Click input ignored.")
		return
	
	# クリック位置をhex座標に変換
	var target_hex = get_hex_at_mouse_position(click_position)
	print("Mouse clicked at %s, targeting hex (%d, %d)" % [click_position, target_hex.q, target_hex.r])
	
	# プレビューハイライトをクリア
	if grid_display:
		grid_display.clear_path_highlight()
	
	# Playerに移動指示を送信
	if player and player.has_method("move_to_hex"):
		# PlayerにGridDisplayのレイアウトを設定
		if grid_display and grid_display.layout:
			player.setup_grid_layout(grid_display.layout)
		player.move_to_hex(target_hex)

# マウスホバー処理（経路プレビュー）
func handle_mouse_hover(hover_position: Vector2):
	# Playerの移動状態をチェック - 移動中はハイライト無効
	var player = get_node_or_null("Player")
	if player and player.is_moving:
		if grid_display:
			grid_display.clear_path_highlight()
		return
	
	# ホバー位置をhex座標に変換
	var target_hex = get_hex_at_mouse_position(hover_position)
	
	# Playerから現在位置への移動経路をプレビュー表示
	if player and player.has_method("preview_path_to_hex") and grid_display:
		var preview_path = player.preview_path_to_hex(target_hex)
		if preview_path and preview_path.size() > 0:
			grid_display.highlight_path_with_start(preview_path, player.current_hex_position)
		else:
			grid_display.clear_path_highlight()

# Playerのパスハイライトシグナルを設定
func setup_path_highlight_signals(player):
	if player.has_signal("path_highlight_requested"):
		if not player.path_highlight_requested.is_connected(_on_path_highlight_requested):
			player.path_highlight_requested.connect(_on_path_highlight_requested)
	if player.has_signal("path_highlight_cleared"):
		if not player.path_highlight_cleared.is_connected(_on_path_highlight_cleared):
			player.path_highlight_cleared.connect(_on_path_highlight_cleared)

# パスハイライト要求時の処理
func _on_path_highlight_requested(hex_path: Array[Hex]):
	if grid_display:
		grid_display.highlight_path(hex_path)
		print("Path highlighted with %d hexes" % hex_path.size())

# パスハイライトクリア時の処理  
func _on_path_highlight_cleared():
	if grid_display:
		grid_display.clear_path_highlight()
		print("Path highlight cleared")