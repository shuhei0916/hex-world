extends GutTest

class_name TestCameraController

const CameraControllerClass = preload("res://scenes/components/camera_controller.gd")

var camera: CameraControllerClass

func before_each():
	camera = CameraControllerClass.new()
	add_child_autofree(camera)

func test_ホイールダウンでズームアウトする():
	camera.zoom = Vector2(1.0, 1.0)
	
	var event = InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_WHEEL_DOWN
	event.pressed = true
	
	camera._unhandled_input(event)
	
	# 即時反映されることを確認
	assert_lt(camera.zoom.x, 1.0, "Zoom should decrease (zoom out) immediately")
	assert_lt(camera.zoom.y, 1.0, "Zoom should decrease (zoom out) immediately")

func test_最小ズーム値より小さくならない():
	camera.zoom = Vector2(camera.min_zoom, camera.min_zoom)
	
	# さらに縮小（ズームアウト）を試みる
	var event = InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_WHEEL_DOWN
	event.pressed = true
	
	camera._unhandled_input(event)
	
	# 即時確認
	assert_almost_eq(camera.zoom.x, camera.min_zoom, 0.001, "Should clamp to min zoom immediately")

func test_最大ズーム値より大きくならない():
	camera.zoom = Vector2(camera.max_zoom, camera.max_zoom)
	
	# さらに拡大（ズームイン）を試みる
	var event = InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_WHEEL_UP
	event.pressed = true
	
	camera._unhandled_input(event)
	
	# 即時確認
	assert_almost_eq(camera.zoom.x, camera.max_zoom, 0.001, "Should clamp to max zoom immediately")
