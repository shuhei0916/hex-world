class_name HUD
extends CanvasLayer

# HUD - ヘッドアップディスプレイ
# ゲーム内のUI要素を統括するコンテナ

@onready var palette_ui: PaletteUI = $PaletteUI


func setup(piece_placer: PiecePlacer):
	if palette_ui:
		palette_ui.setup(piece_placer)
	else:
		push_warning("HUD: PaletteUI node not found.")
