class_name Main
extends Node2D

const PaletteScript = preload("res://scenes/ui/palette/palette.gd")

@onready var hud: HUD = $HUD
@onready var grid_manager:= $GridManager

var palette: Palette

func _init():
	palette = PaletteScript.new()

func _ready():
	grid_manager.create_hex_grid(grid_manager.grid_radius)
	
	hud.setup_ui(palette)

func _unhandled_input(event):
	if event is InputEventKey and event.pressed and not event.is_echo():
		if event.keycode >= KEY_1 and event.keycode <= KEY_9:
			if palette:
				var index = event.keycode - KEY_1
				palette.select_slot(index)
