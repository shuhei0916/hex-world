class_name CameraController
extends Camera2D

# ズーム設定
@export var min_zoom: float = 0.1
@export var max_zoom: float = 5.0
@export var zoom_sensitivity: float = 0.1

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.pressed:
			if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				# ズームアウト（値を小さくする）
				change_zoom(-zoom_sensitivity)
			elif event.button_index == MOUSE_BUTTON_WHEEL_UP:
				# ズームイン（値を大きくする）
				change_zoom(zoom_sensitivity)

func change_zoom(amount: float) -> void:
	# 現在のズーム値を基準にする
	var new_zoom_val = zoom.x + amount
	
	# 範囲制限
	new_zoom_val = clamp(new_zoom_val, min_zoom, max_zoom)
	
	# 直接適用
	zoom = Vector2(new_zoom_val, new_zoom_val)