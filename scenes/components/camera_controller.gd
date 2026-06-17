class_name CameraController
extends Camera2D

@export var min_zoom: float = 0.1
@export var max_zoom: float = 5.0
@export var zoom_sensitivity: float = 0.1
@export var move_speed: float = 500.0


func _ready() -> void:
	change_zoom(-0.1)


func _process(delta: float) -> void:
	var direction = _get_input_direction()
	position += _calc_move_delta(direction, delta)


func _get_input_direction() -> Vector2:
	var direction = Vector2.ZERO
	if Input.is_key_pressed(KEY_W):
		direction.y -= 1
	if Input.is_key_pressed(KEY_S):
		direction.y += 1
	if Input.is_key_pressed(KEY_A):
		direction.x -= 1
	if Input.is_key_pressed(KEY_D):
		direction.x += 1
	return direction


func _calc_move_delta(direction: Vector2, delta: float) -> Vector2:
	if direction == Vector2.ZERO:
		return Vector2.ZERO
	return direction.normalized() * move_speed / zoom.x * delta


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
