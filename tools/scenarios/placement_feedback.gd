extends RefCounted
## 実際のマウス入力で、設置の手応えを確かめる:
## - キャラクターの立っているマスに機械を置くと、キャラクターが施設の端まで押し出されて置け、カメラが追う
## - 既に置いてあるマスをクリックすると、カーソルの近くに理由が出てエラー音が鳴る
## - 機械を置けないマスに合わせると、ゴーストが赤くなる

const PLAYER_HEX := Vector2i(3, -1)


func run(scene: Node) -> void:
	var world: World = scene.world
	var chunk: Chunk = world.get_active_chunk()
	var placer: PiecePlacer = scene.piece_placer
	HubGoals.creative_mode = true
	world.place_player(world.get_active_hex(), PLAYER_HEX)
	await scene.get_tree().process_frame

	var start_position := world.player.position
	# ヘッドレスの画面は小さく、カメラをキャラクターに合わせるとクリック位置が HUD に重なるので動かさない
	var camera_before: Vector2 = scene.camera.position
	scene.hud.slot_buttons[2].button_pressed = true
	scene.hud.on_slot_pressed(2)
	print("選んだピース: %s" % placer.selected_scene.resource_path)

	await _click(scene, chunk, PLAYER_HEX)
	print("[キャラクターの足元をクリック]")
	print("  置いたピース = %s" % chunk.get_piece_at_hex(PLAYER_HEX))
	print(
		(
			"  キャラクター: マス %s → %s（立てる位置か = %s）"
			% [
				PLAYER_HEX,
				world.player.hex,
				PlayerCharacter.can_stand_at(chunk, world.player.position),
			]
		)
	)
	print(
		(
			"  押し出した距離 = %.1f px（隣のマスの中心までは %.1f px）"
			% [
				start_position.distance_to(world.player.position),
				chunk.hex_to_pixel(Vector2i(0, 0)).distance_to(chunk.hex_to_pixel(Vector2i(1, 0))),
			]
		)
	)
	print("  メッセージ表示 = %s" % scene.hud.cursor_message.visible)
	for i in range(30):
		await scene.get_tree().process_frame
	print(
		(
			"  カメラ: %s → 30フレーム後 %s（キャラクター %s）"
			% [camera_before, scene.camera.position, world.get_player_position()]
		)
	)

	await _click(scene, chunk, PLAYER_HEX)
	print("[置いたマスをもう一度クリック]")
	print(
		(
			"  メッセージ = %s「%s」 位置 %s"
			% [
				scene.hud.cursor_message.visible,
				scene.hud.cursor_message.text,
				scene.hud.cursor_message.position,
			]
		)
	)
	print("  エラー音 = %s" % scene.sfx_player.get_node("PlacementDenied").playing)
	print("  ゴーストの色 = %s" % placer.snap_preview.modulate)

	await _move(scene, chunk, Vector2i(3, 1))
	print("[空いたマスに合わせる] ゴーストの色 = %s" % placer.snap_preview.modulate)


func _screen(scene: Node, chunk: Chunk, hex: Vector2i) -> Vector2:
	return scene.get_viewport().get_canvas_transform() * chunk.to_global(chunk.hex_to_pixel(hex))


func _move(scene: Node, chunk: Chunk, hex: Vector2i) -> void:
	var motion := InputEventMouseMotion.new()
	motion.position = _screen(scene, chunk, hex)
	motion.global_position = motion.position
	Input.parse_input_event(motion)
	await scene.get_tree().process_frame


func _click(scene: Node, chunk: Chunk, hex: Vector2i) -> void:
	await _move(scene, chunk, hex)
	for pressed in [true, false]:
		var button := InputEventMouseButton.new()
		button.button_index = MOUSE_BUTTON_LEFT
		button.pressed = pressed
		button.position = _screen(scene, chunk, hex)
		button.global_position = button.position
		Input.parse_input_event(button)
		await scene.get_tree().process_frame
