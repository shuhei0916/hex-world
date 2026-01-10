class_name HUD
extends CanvasLayer

# HUD - ヘッドアップディスプレイ
# ゲーム内のUI要素を統括するコンテナ

@onready var palette_ui: PaletteUI = $PaletteUI


func setup_ui(palette: Palette):
	if palette_ui:
		palette_ui.set_palette(palette)
	else:
		push_warning("HUD: PaletteUI node not found.")
