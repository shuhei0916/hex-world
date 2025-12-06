class_name CameraController
extends Camera2D

@export var min_zoom: float = 0.1
@export var max_zoom: float = 5.0
@export var zoom_sensitivity: float = 0.1

func _ready() -> void:
	change_zoom(0.3)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.pressed:
			if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				change_zoom(-zoom_sensitivity)
			elif event.button_index == MOUSE_BUTTON_WHEEL_UP:
				change_zoom(zoom_sensitivity)

func change_zoom(amount: float) -> void:
	var new_zoom_val = zoom.x + amount
	new_zoom_val = clamp(new_zoom_val, min_zoom, max_zoom)
	zoom = Vector2(new_zoom_val, new_zoom_val)
