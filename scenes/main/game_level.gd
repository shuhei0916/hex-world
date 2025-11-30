@tool
class_name GameLevel
extends Node2D

# GameLevel - ゲームの統合コントローラー
# 各コンポーネントを統括し、データの受け渡しを行う

const PaletteScript = preload("res://scenes/ui/palette/palette.gd")
const GridManagerClass = preload("res://scenes/components/grid/grid_manager.gd")

# エディタで配置されたノードへの参照
@onready var hud: HUD = $HUD
@onready var grid_manager: GridManagerClass = $GridManager

var palette: Palette

func _init():
	if not Engine.is_editor_hint():
		palette = PaletteScript.new()

func _ready():
	# GridManagerの初期化
	if grid_manager:
		grid_manager.create_hex_grid(grid_manager.grid_radius)
	
	# HUDのセットアップ (Paletteデータの注入)
	if not Engine.is_editor_hint():
		if hud:
			hud.setup_ui(palette)
		else:
			push_warning("GameLevel: HUD node not found. Check if HUD is added to GameLevel scene.")

func _unhandled_input(event):
	if Engine.is_editor_hint():
		return
		
	if event is InputEventKey and event.pressed and not event.is_echo():
		if event.keycode >= KEY_1 and event.keycode <= KEY_9:
			if palette:
				var index = event.keycode - KEY_1
				palette.select_slot(index)
