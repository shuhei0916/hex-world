@tool
class_name GameLevel
extends Node2D

# GameLevel - ゲームの統合コントローラー
# 各コンポーネントを統括し、データの受け渡しを行う

const PaletteScript = preload("res://scripts/palette.gd")
const PaletteUIScript = preload("res://scripts/palette_ui.gd")

var grid_display: GridDisplay
var palette: Palette
var palette_ui: PaletteUI

func _init():
	# GridDisplayの初期化
	grid_display = GridDisplay.new()
	# 必要に応じて設定
	grid_display.grid_radius = 4
	
	# Paletteの初期化
	# エディタ動作と切り分けるため、実体化は_initでも行うが、ロジックは実行時のみ推奨
	palette = PaletteScript.new()

func _ready():
	# ツリーに追加
	if not grid_display.is_inside_tree():
		add_child(grid_display)
	
	if not grid_display.is_connected("grid_updated", _on_grid_updated):
		grid_display.grid_updated.connect(_on_grid_updated)
	
	if not Engine.is_editor_hint():
		_setup_ui()

func _setup_ui():
	# CanvasLayerを作成してHUDを表示
	var canvas_layer = CanvasLayer.new()
	canvas_layer.name = "UILayer"
	add_child(canvas_layer)
	
	# PaletteUIをロード
	var ui_scene = load("res://scenes/PaletteUI.tscn")
	if ui_scene:
		palette_ui = ui_scene.instantiate()
	else:
		palette_ui = PaletteUIScript.new()
	
	palette_ui.name = "PaletteUI"
	# パレットを注入
	palette_ui.set_palette(palette)
	
	canvas_layer.add_child(palette_ui)

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