extends RefCounted

# 戦闘中も、建築のときと同じ操作でカメラを動かせることを確かめる。
# 実際のマウス入力で: 隣の chunk に挑む → 中ボタンドラッグでパン → ホイールで寄せる
# → 動かしたあとの画面でマスをクリックして歩く（クリックした位置のマスに動くか）
# → ホイールで引けるだけ引く（地図には切り替わらない）→ 撤退（戦闘前の地図の見え方に戻る）、
# までを出力する。


func run(scene: Node) -> void:
	var east = Vector2i(1, 0)
	# ヘッドレスの画面は 64x64 で、戦闘のボタンが盤面に重なってクリックを受けてしまうので広げる
	scene.get_window().size = Vector2i(1280, 720)
	scene._enter_world_map_mode()
	await scene.get_tree().process_frame
	print("[map] %s" % _state(scene))

	await _click(scene, _tile_screen_pos(scene, east))
	var battle_scene: BattleScene = scene.battle_overlay.battle_scene
	battle_scene.animations_enabled = false
	var battle: Battle = battle_scene.battle
	print("[battle start] %s" % _state(scene))

	await _middle_drag(scene, Vector2(640, 360), Vector2(540, 300))
	print("[middle drag 100px left, 60px up] %s" % _state(scene))

	for i in range(2):
		await _wheel(scene, MOUSE_BUTTON_WHEEL_UP)
	print("[wheel up x2] %s" % _state(scene))

	# カメラを動かしたあとも、クリックした位置のマスに歩く
	battle_scene.get_node("Hud/SkillBar").get_child(0).pressed.emit()
	var from = battle.player.position
	var target = _reachable_target(battle, battle_scene.skill_turn.skills[0].value)
	var screen_pos = _hex_screen_pos(scene, battle_scene, target)
	await _click(scene, screen_pos)
	print(
		(
			"[move after camera] %s -> click %s at screen %s -> player at %s"
			% [from, target, screen_pos.round(), battle.player.position]
		)
	)

	for i in range(30):
		await _wheel(scene, MOUSE_BUTTON_WHEEL_DOWN)
	print("[wheel down x30] %s" % _state(scene))

	scene.battle_overlay.retreat()
	await scene.get_tree().process_frame
	print("[retreat] %s min_zoom=%.2f" % [_state(scene), scene.camera.min_zoom])


func _state(scene: Node) -> String:
	return (
		"battle_open=%s local=%s active=%s camera=%s zoom=%.3f"
		% [
			scene.battle_overlay.is_open(),
			scene.is_local_mode(),
			scene.world.get_active_hex(),
			scene.camera.position.round(),
			scene.camera.zoom.x,
		]
	)


func _tile_screen_pos(scene: Node, hex: Vector2i) -> Vector2:
	var view: WorldMapView = scene.world_map_view
	var world_pos = view.to_global(view.get_tile_position(hex))
	return scene.get_viewport().get_canvas_transform() * world_pos


# 戦場のマスの、画面上の位置
func _hex_screen_pos(scene: Node, battle_scene: BattleScene, hex: Vector2i) -> Vector2:
	var world_pos = battle_scene.to_global(Hex.to_pixel(hex, BattleScene.HEX_SIZE))
	return scene.get_viewport().get_canvas_transform() * world_pos


# いちばん遠くまで歩けるマス
func _reachable_target(battle: Battle, steps: int) -> Vector2i:
	var reachable = battle.field.reachable(battle.player.position, steps)
	var best = battle.player.position
	for hex in reachable:
		if reachable[hex] > reachable.get(best, 0):
			best = hex
	return best


func _button(button: MouseButton, pos: Vector2, pressed: bool) -> void:
	var ev := InputEventMouseButton.new()
	ev.button_index = button
	ev.position = pos
	ev.global_position = pos
	ev.pressed = pressed
	Input.parse_input_event(ev)
	Input.flush_buffered_events()


func _motion(pos: Vector2, relative := Vector2.ZERO) -> void:
	var motion := InputEventMouseMotion.new()
	motion.position = pos
	motion.global_position = pos
	motion.relative = relative
	Input.parse_input_event(motion)
	Input.flush_buffered_events()


func _click(scene: Node, pos: Vector2) -> void:
	_motion(pos)
	_button(MOUSE_BUTTON_LEFT, pos, true)
	_button(MOUSE_BUTTON_LEFT, pos, false)
	await scene.get_tree().process_frame


func _middle_drag(scene: Node, from: Vector2, to: Vector2) -> void:
	_motion(from)
	_button(MOUSE_BUTTON_MIDDLE, from, true)
	_motion(to, to - from)
	_button(MOUSE_BUTTON_MIDDLE, to, false)
	await scene.get_tree().process_frame


func _wheel(scene: Node, button: MouseButton) -> void:
	var pos = Vector2(640, 360)
	_button(button, pos, true)
	_button(button, pos, false)
	await scene.get_tree().process_frame
