extends Node2D

# MainScene - メインゲームシーン制御
# HexFRVRゲームのメインシーン管理

@onready var grid_display = $GridDisplay

func _ready():
	print("MainScene initialized")
	setup_game()

func _process(_delta):
	update_debug_display()

func setup_game():
	# グリッド設定（Unity版のような中規模グリッド）
	if grid_display:
		grid_display.create_hex_grid(4)  # 半径4の六角形グリッド
		grid_display.register_grid_with_manager()
		print("Grid created with %d hexes" % grid_display.get_grid_hex_count())
		
		# グリッドを視覚的に描画
		grid_display.draw_grid()
		print("Grid drawing completed with %d visual tiles" % grid_display.get_child_count())

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
		debug_label.text = "Hex: (%d, %d)" % [hex_coord.q, hex_coord.r]