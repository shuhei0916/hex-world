extends RefCounted
## 実際のマウス入力で、ピースを選んだままツールバーを触ったときの振る舞いを確かめる:
## - 盤面からツールバーへマウスを移すと、盤面のゴーストが消え、マスの選択も外れる
## - ツールバーの上で左クリックしても盤面には置かれない
## - 選んでいるボタンをもう一度クリックすると解除され、切替パネルも消える
## - ツールバーの上で右クリックすると選択が解除される
## ヘッドレスの画面は小さくツールバーが画面外に出るので、screenshot.sh（描画あり）で動かす


func run(scene: Node) -> void:
	var hud: HUD = scene.hud
	var placer: PiecePlacer = scene.piece_placer
	var chunk: Chunk = scene.world.get_active_chunk()
	await scene.get_tree().process_frame

	hud.select_slot(1)  # Miner（T1/T2 の切替パネルが出る）
	await _settle(scene)
	await _move(scene, scene.get_viewport().get_visible_rect().size * Vector2(0.5, 0.4))
	print("[盤面の上] マス = %s ゴースト表示 = %s" % [placer.current_hovered_hex, placer.snap_preview.visible])

	var miner_button: Control = hud.slot_buttons[1]
	await _move(scene, miner_button.get_global_rect().get_center())
	print(
		"[ツールバーの上] マス = %s ゴースト表示 = %s" % [placer.current_hovered_hex, placer.snap_preview.visible]
	)

	var pieces_before := chunk.get_children().size()
	await _click(scene, miner_button.get_global_rect().get_center(), MOUSE_BUTTON_LEFT)
	print(
		(
			"[選んでいるボタンをもう一度クリック] 選択 = %d 切替パネル = %s 盤面のノード数 %d → %d"
			% [
				hud.get_active_index(),
				hud.variant_panel.visible,
				pieces_before,
				chunk.get_children().size()
			]
		)
	)

	hud.select_slot(1)
	await _click(scene, miner_button.get_global_rect().get_center(), MOUSE_BUTTON_RIGHT)
	print(
		(
			"[ツールバーで右クリック] 選択 = %d 切替パネル = %s 押された見た目 = %s"
			% [hud.get_active_index(), hud.variant_panel.visible, miner_button.button_pressed]
		)
	)


func _settle(scene: Node) -> void:
	for i in 3:
		await scene.get_tree().process_frame


func _move(scene: Node, position: Vector2) -> void:
	var motion := InputEventMouseMotion.new()
	motion.position = position
	motion.global_position = position
	Input.parse_input_event(motion)
	await _settle(scene)


func _click(scene: Node, position: Vector2, button_index: MouseButton) -> void:
	for pressed in [true, false]:
		var button := InputEventMouseButton.new()
		button.button_index = button_index
		button.pressed = pressed
		button.position = position
		button.global_position = position
		Input.parse_input_event(button)
		await _settle(scene)
