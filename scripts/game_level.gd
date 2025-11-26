class_name GameLevel
extends Node2D

# GameLevel - ゲームの統合コントローラー
# 各コンポーネントを統括し、データの受け渡しを行う

var grid_display: GridDisplay

func _init():
	# GridDisplayの初期化
	grid_display = GridDisplay.new()
	# 必要に応じて設定
	grid_display.grid_radius = 4

func _ready():
	# ツリーに追加
	add_child(grid_display)
	
	# シグナル接続
	grid_display.grid_updated.connect(_on_grid_updated)

func _on_grid_updated(hexes: Array[Hex]):
	# GridManagerに登録
	if not Engine.is_editor_hint():
		for hex in hexes:
			GridManager.register_grid_hex(hex)
