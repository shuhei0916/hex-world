extends GutTest

## 研究ツリーは横（ハブのレベルの順）に伸びていく。画面に収まらない分は、
## パネルを画面からはみ出させず、ツリーを左右にスクロールして見る（ホイール・ドラッグ）。

var panel: ResearchPanel
var _window_size: Vector2i


# ヘッドレスのウィンドウは小さいので、実際のマウス操作の間だけ広げる
func before_all():
	_window_size = get_window().size
	get_window().size = Vector2i(1280, 720)


func after_all():
	get_window().size = _window_size


func before_each():
	HubGoals.reset()
	panel = ResearchPanel.new()
	add_child_autofree(panel)
	panel.toggle()


func after_each():
	HubGoals.reset()


func _settle_layout() -> void:
	await get_tree().process_frame
	await get_tree().process_frame


# ツリーの幅いっぱいは収まらない狭い画面にする
func _narrow() -> void:
	panel.fit_to_width(700.0)
	await _settle_layout()


func _mouse_button(position: Vector2, index: MouseButton, pressed: bool) -> InputEventMouseButton:
	var ev := InputEventMouseButton.new()
	ev.button_index = index
	ev.pressed = pressed
	ev.position = position
	ev.global_position = position
	return ev


func _motion(position: Vector2, relative: Vector2, mask: MouseButtonMask) -> InputEventMouseMotion:
	var ev := InputEventMouseMotion.new()
	ev.position = position
	ev.global_position = position
	ev.relative = relative
	ev.button_mask = mask
	return ev


# ツリーの見えている範囲で、ノードの無い場所（列の見出しの行の右端）
func _empty_point() -> Vector2:
	var rect := panel.get_tree_scroll().get_global_rect()
	return Vector2(rect.end.x - 20, rect.position.y + 10)


func test_狭い画面でもパネルは画面からはみ出さない():
	await _narrow()
	assert_lte(panel.get_combined_minimum_size().x, 700.0)


func test_狭い画面では収まらない分を横にスクロールできる():
	await _narrow()
	var scroll := panel.get_tree_scroll()
	assert_gt(scroll.get_h_scroll_bar().max_value, scroll.size.x + 1.0)


func test_広い画面ではスクロールせずにツリー全体が見える():
	panel.fit_to_width(1600.0)
	await _settle_layout()
	var scroll := panel.get_tree_scroll()
	assert_lte(scroll.get_h_scroll_bar().max_value, scroll.size.x + 1.0)


func test_ノードの上でホイールを回すとツリーが横にスクロールする():
	await _narrow()
	var scroll := panel.get_tree_scroll()
	var node := panel.get_node_button(Research.all_ids()[0])
	var point := node.get_global_rect().get_center()
	get_viewport().push_input(_mouse_button(point, MOUSE_BUTTON_WHEEL_DOWN, true))
	get_viewport().push_input(_mouse_button(point, MOUSE_BUTTON_WHEEL_DOWN, false))
	await _settle_layout()
	assert_gt(scroll.scroll_horizontal, 0)


func test_ドラッグするとつかんだ方向へツリーが動く():
	await _narrow()
	var scroll := panel.get_tree_scroll()
	var start := _empty_point()
	get_viewport().push_input(_mouse_button(start, MOUSE_BUTTON_LEFT, true))
	get_viewport().push_input(
		_motion(start + Vector2(-120, 0), Vector2(-120, 0), MOUSE_BUTTON_MASK_LEFT)
	)
	get_viewport().push_input(_mouse_button(start + Vector2(-120, 0), MOUSE_BUTTON_LEFT, false))
	await _settle_layout()
	# 左へつかんで引くと、右側が見えてくる
	assert_almost_eq(scroll.scroll_horizontal, 120, 2)


func test_ドラッグを離したあとはマウスを動かしてもスクロールしない():
	await _narrow()
	var scroll := panel.get_tree_scroll()
	var start := _empty_point()
	get_viewport().push_input(_mouse_button(start, MOUSE_BUTTON_LEFT, true))
	get_viewport().push_input(_mouse_button(start, MOUSE_BUTTON_LEFT, false))
	get_viewport().push_input(_motion(start + Vector2(-80, 0), Vector2(-80, 0), 0))
	await _settle_layout()
	assert_eq(scroll.scroll_horizontal, 0)


func test_ノードをクリックすると選ばれる():
	await _narrow()
	var id: String = Research.all_ids()[1]
	var point := panel.get_node_button(id).get_global_rect().get_center()
	get_viewport().push_input(_mouse_button(point, MOUSE_BUTTON_LEFT, true))
	get_viewport().push_input(_mouse_button(point, MOUSE_BUTTON_LEFT, false))
	await _settle_layout()
	assert_eq(panel.get_selected(), id)


func test_幅を合わせたあともパネルは画面の中央にある():
	await _narrow()
	var center := panel.get_global_rect().get_center()
	assert_almost_eq(center, panel.get_viewport_rect().get_center(), Vector2(1, 1))


func test_横のスクロールバーがノードの名前に重ならない():
	await _narrow()
	var scroll := panel.get_tree_scroll()
	var bar_height := scroll.get_h_scroll_bar().get_combined_minimum_size().y
	assert_gte(scroll.size.y, scroll.get_child(0).size.y + bar_height)
