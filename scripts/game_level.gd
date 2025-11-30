@tool
class_name GameLevel
extends Node2D

# GameLevel - ゲームの統合コントローラー
# 各コンポーネントを統括し、データの受け渡しを行う

const PaletteScript = preload("res://scripts/palette.gd")

# HUDはエディタで配置済みと想定
@onready var hud: HUD = $HUD

# GridDisplayは動的に生成（後で静的配置に移行推奨）
var grid_display: GridDisplay
var palette: Palette

func _init():
	# GridDisplayの初期化
	grid_display = GridDisplay.new()
	grid_display.grid_radius = 4
	
	if not Engine.is_editor_hint():
		palette = PaletteScript.new()

func _ready():
	# GridDisplayをツリーに追加
	if not grid_display.is_inside_tree():
		add_child(grid_display)
		
	# シグナル接続
	if not grid_display.is_connected("grid_updated", _on_grid_updated):
		grid_display.grid_updated.connect(_on_grid_updated)
	
	# HUDのセットアップ
	if not Engine.is_editor_hint():
		if hud:
			hud.setup_ui(palette)
		else:
			# HUDが見つからない場合は警告（テスト時などシーンから作らない場合に備える）
			pass

func _on_grid_updated(hexes: Array[Hex]):
	# GridManagerに登録
	if not Engine.is_editor_hint():
		for hex in hexes:
			GridManager.register_grid_hex(hex)

func _unhandled_input(event):
	if Engine.is_editor_hint():
		return
		
	if event is InputEventKey and event.pressed and not event.is_echo():
		if event.keycode >= KEY_1 and event.keycode <= KEY_9:
			if palette:
				var index = event.keycode - KEY_1
				palette.select_slot(index)