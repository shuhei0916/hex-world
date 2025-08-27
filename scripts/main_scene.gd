extends Node2D

# MainScene - メインゲームシーン制御
# HexFRVRゲームのメインシーン管理

@onready var grid_display = $GridDisplay

func _ready():
	print("MainScene initialized")
	setup_game()

func setup_game():
	# グリッド設定（Unity版のような中規模グリッド）
	if grid_display:
		grid_display.create_hex_grid(4)  # 半径4の六角形グリッド
		grid_display.register_grid_with_manager()
		print("Grid created with %d hexes" % grid_display.get_grid_hex_count())