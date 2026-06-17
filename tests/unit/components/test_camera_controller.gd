extends GutTest

var camera: CameraController


func before_each():
	camera = CameraController.new()
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


func test_方向ゼロのとき移動量はゼロ():
	var delta = camera._calc_move_delta(Vector2.ZERO, 1.0)
	assert_eq(delta, Vector2.ZERO)


func test_対角移動でも速度が一定になる():
	camera.zoom = Vector2(1.0, 1.0)
	var straight = camera._calc_move_delta(Vector2(1, 0), 1.0)
	var diagonal = camera._calc_move_delta(Vector2(1, 1), 1.0)
	assert_almost_eq(straight.length(), diagonal.length(), 0.001)


func test_zoomが大きいほどworld移動量が小さくなる():
	camera.zoom = Vector2(1.0, 1.0)
	var delta_zoom1 = camera._calc_move_delta(Vector2(1, 0), 1.0)
	camera.zoom = Vector2(2.0, 2.0)
	var delta_zoom2 = camera._calc_move_delta(Vector2(1, 0), 1.0)
	assert_almost_eq(delta_zoom1.x * 1.0, delta_zoom2.x * 2.0, 0.001)
