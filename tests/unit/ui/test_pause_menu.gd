extends GutTest

const PauseMenuScene = preload("res://scenes/ui/pause_menu/pause_menu.tscn")

var menu: PauseMenu


func before_each():
	menu = PauseMenuScene.instantiate()
	add_child_autofree(menu)


func after_each():
	get_tree().paused = false


func _esc_event() -> InputEventKey:
	var event = InputEventKey.new()
	event.keycode = KEY_ESCAPE
	event.pressed = true
	return event


func test_初期状態では非表示でゲームは止まっていない():
	assert_false(menu.visible)
	assert_false(get_tree().paused)


func test_ESCでメニューが開きゲームが一時停止する():
	menu._unhandled_input(_esc_event())
	assert_true(menu.visible)
	assert_true(get_tree().paused)


func test_メニュー表示中にESCで閉じてゲームが再開する():
	menu._unhandled_input(_esc_event())
	menu._unhandled_input(_esc_event())
	assert_false(menu.visible)
	assert_false(get_tree().paused)


func test_再開ボタンでメニューが閉じてゲームが再開する():
	menu.open()
	menu.resume_button.pressed.emit()
	assert_false(menu.visible)
	assert_false(get_tree().paused)


func test_終了ボタンで終了要求が通知される():
	watch_signals(menu)
	menu.open()
	menu.quit_button.pressed.emit()
	assert_signal_emitted(menu, "quit_requested")


func test_一時停止中もメニューは入力を受け付ける():
	assert_eq(menu.process_mode, Node.PROCESS_MODE_ALWAYS)


func test_キーを離したイベントやリピートでは開閉しない():
	var release = _esc_event()
	release.pressed = false
	menu._unhandled_input(release)
	var echo = _esc_event()
	echo.echo = true
	menu._unhandled_input(echo)
	assert_false(menu.visible)


func test_セーブボタンでセーブ要求が通知されメニューは開いたまま():
	watch_signals(menu)
	menu.open()
	menu.save_button.pressed.emit()
	assert_signal_emitted(menu, "save_requested")
	assert_true(menu.visible)


func test_やり直しボタンは1回目は確認を求め2回目でやり直し要求を通知する():
	watch_signals(menu)
	menu.open()
	menu.new_game_button.pressed.emit()
	assert_signal_not_emitted(menu, "new_game_requested")
	assert_eq(menu.new_game_button.text, "本当にやり直す（もう一度押す）")
	menu.new_game_button.pressed.emit()
	assert_signal_emitted(menu, "new_game_requested")


func test_メニューを開き直すとやり直しの確認とメッセージは元に戻る():
	menu.open()
	menu.new_game_button.pressed.emit()
	menu.show_status("セーブしました")
	menu.close()
	menu.open()
	assert_eq(menu.new_game_button.text, "最初からやり直す")
	assert_eq(menu.status_label.text, "")
