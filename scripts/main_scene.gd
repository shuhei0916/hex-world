extends Node2D

# MainScene - 工場設計ゲームのメインシーン制御
# Hex工場設計システムのメインシーン管理

@onready var grid_display = $GridDisplay
@onready var camera = $Camera2D
@onready var palette_ui = $UILayer/PaletteUI
var debug_mode: bool = false

func _ready():
	print("MainScene initialized")
	setup_game()

func _process(_delta):
	update_debug_display()

func _input(event):
	if palette_ui:
		palette_ui.process_input_event(event)
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_F2:
			toggle_debug_mode()
	elif event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			var mouse_pos = get_global_mouse_position()
			handle_grid_click(mouse_pos)
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP:
			zoom_camera(1.1)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			zoom_camera(0.9)
	elif event is InputEventMouseMotion:
		if Input.is_action_pressed("ui_select"):  # マウス中ボタンでカメラパン
			pan_camera(-event.relative)

func setup_game():
	# グリッド設定（工場設計用の中規模グリッド）
	if grid_display:
		grid_display.create_hex_grid(4)  # 半径6の六角形グリッド（工場設計用に拡大）
		grid_display.register_grid_with_manager()
		print("Factory grid created with %d hexes" % grid_display.get_grid_hex_count())
		
		# グリッドを視覚的に描画
		grid_display.draw_grid()
		print("Grid drawing completed with %d visual tiles" % grid_display.get_child_count())
		
		# カメラの初期設定
		setup_camera()

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

# グリッドクリック処理（工場設計用）
func handle_grid_click(click_position: Vector2):
	# クリック位置をhex座標に変換
	var target_hex = get_hex_at_mouse_position(click_position)
	print("Grid clicked at %s, hex (%d, %d)" % [click_position, target_hex.q, target_hex.r])
	
	# 境界チェック
	if grid_display and not grid_display.is_within_bounds(target_hex):
		print("Target hex (%d, %d) is outside grid boundaries." % [target_hex.q, target_hex.r])
		return
	
	# TODO: 工場施設配置処理をここに実装
	# 現在は選択されたhexをハイライト表示
	highlight_selected_hex(target_hex)

# カメラ操作機能
func setup_camera():
	camera.position = Vector2.ZERO
	camera.zoom = Vector2(1.0, 1.0)

func zoom_camera(zoom_factor: float):
	var new_zoom = camera.zoom * zoom_factor
	# ズーム制限
	new_zoom.x = clamp(new_zoom.x, 0.3, 3.0)
	new_zoom.y = clamp(new_zoom.y, 0.3, 3.0)
	camera.zoom = new_zoom

func pan_camera(offset: Vector2):
	camera.position += offset * (1.0 / camera.zoom.x)

# 選択されたhexをハイライト表示
func highlight_selected_hex(hex_coord: Hex):
	if grid_display:
		# TODO: 単一hexハイライト機能を実装
		print("Selected hex (%d, %d) for factory placement" % [hex_coord.q, hex_coord.r])
