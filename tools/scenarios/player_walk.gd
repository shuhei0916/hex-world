extends RefCounted

## キャラクターの歩行の確認。実際のキー入力で D・W・A・D+S を押し続け、マスに縛られず自由に動く様子、
## chunk の端やハブでふさがれる様子、カメラが追うことを出力する。


func run(scene: Node) -> void:
	var world: World = scene.world
	var tree = scene.get_tree()
	print("はじめ: ", _describe(scene))
	await _hold(tree, KEY_D, 0.5)
	print("D を 0.5 秒: ", _describe(scene))
	await _hold(tree, KEY_W, 0.5)
	print("W を 0.5 秒: ", _describe(scene))
	await _hold(tree, KEY_A, 1.5)
	print("A を 1.5 秒: ", _describe(scene))
	await _hold_two(tree, KEY_D, KEY_S, 0.5)
	print("D+S を 0.5 秒（右下へ斜め）: ", _describe(scene))
	world.place_player(Vector2i(0, 0), Vector2i(2, 0))
	await _hold(tree, KEY_A, 0.5)
	print("ハブの東2マスから A を 0.5 秒（ハブは通れない）: ", _describe(scene))
	# ハブの左下で、体の上の端がハブの斜めの辺にかかる高さから D（斜めの辺に沿って滑ってハブの下を抜ける）
	var chunk: Chunk = world.get_active_chunk()
	world.place_player(Vector2i(0, 0), Vector2i(-1, 1))
	world.move_player_to(chunk.hex_to_pixel(Vector2i(-1, 1)) + Vector2(0, -10))
	print("ハブの左下に寄せた: ", _describe(scene))
	await _hold(tree, KEY_D, 0.6)
	print("そこから D を 0.6 秒: ", _describe(scene))


func _hold(tree: SceneTree, keycode: Key, seconds: float) -> void:
	_send_key(keycode, true)
	await tree.create_timer(seconds).timeout
	_send_key(keycode, false)
	await tree.create_timer(0.2).timeout


func _hold_two(tree: SceneTree, first: Key, second: Key, seconds: float) -> void:
	_send_key(first, true)
	_send_key(second, true)
	await tree.create_timer(seconds).timeout
	_send_key(first, false)
	_send_key(second, false)
	await tree.create_timer(0.2).timeout


func _send_key(keycode: Key, pressed: bool) -> void:
	var event := InputEventKey.new()
	event.keycode = keycode
	event.physical_keycode = keycode
	event.pressed = pressed
	Input.parse_input_event(event)


func _describe(scene: Node) -> String:
	var world: World = scene.world
	return (
		"マス %s / カメラ %s / キャラクター（画面の位置） %s"
		% [world.player.hex, scene.camera.position.round(), world.get_player_position().round()]
	)
