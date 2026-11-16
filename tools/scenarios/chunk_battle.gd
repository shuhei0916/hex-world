extends RefCounted

# ワールドマップの霧と、隣の chunk を戦って解放する流れを確かめる。
# 実際のマウス入力で: 霧のタイルをクリック（何も起きない）→ 隣のタイルをクリック（戦闘が始まる）
# → 移動カードを選んで盤面をクリック（主人公が動く）→ 敵を取り除いて勝利 → 結果を閉じて解放、
# 解放した chunk をクリックして入る、までを出力する。


func run(scene: Node) -> void:
	var view: WorldMapView = scene.world_map_view
	var east = Hex.new(1, 0)
	var far = Hex.new(2, 0)
	scene._enter_world_map_mode()
	await scene.get_tree().process_frame
	for hex in [Hex.new(0, 0), east, far]:
		view.set_hovered_chunk(hex)
		print(
			(
				"[map] %s color=%s hover=%s"
				% [hex, view.get_tile_color(hex).to_html(false), _one_line(view)]
			)
		)

	await _click(scene, _tile_screen_pos(scene, far))
	print("[click fog] battle_open=%s local=%s" % [_is_open(scene), scene.is_local_mode()])

	await _click(scene, _tile_screen_pos(scene, east))
	var overlay: BattleOverlay = scene.battle_overlay
	print("[click frontier] battle_open=%s local=%s" % [_is_open(scene), scene.is_local_mode()])
	var battle_scene: BattleScene = overlay.battle_scene
	battle_scene.animations_enabled = false
	var battle: Battle = battle_scene.battle
	print(
		(
			"[battle] stage=%d enemies=%d player_hp=%d hand=%s"
			% [
				ChunkBattle.stage_for(east),
				battle.enemies().size(),
				battle.player.hp,
				battle_scene.card_turn.deck.hand.map(func(card): return card.title),
			]
		)
	)

	var move_card = _first_move_card(battle_scene)
	if move_card == null:
		print("[move] 手札に移動カードが無い（この乱数では確かめられない）")
	else:
		var from = battle.player.position
		battle_scene.select_card(move_card)
		var target = _reachable_target(battle, move_card.value)
		var screen = battle_scene.position + BattleHex.to_pixel(target, BattleScene.HEX_SIZE)
		await _click(scene, screen)
		print(
			(
				"[move] %s -> click %s -> player at %s (energy %d)"
				% [from, target, battle.player.position, battle_scene.card_turn.energy]
			)
		)

	var camera_before = scene.camera.position
	Input.action_press("ui_accept")
	await scene.get_tree().process_frame
	Input.action_release("ui_accept")
	print("[during battle] camera moved=%s" % [scene.camera.position != camera_before])

	for enemy in battle.enemies():
		battle.field.remove_unit(enemy)
	battle_scene.refresh()
	print("[win] result=%s owned=%s" % [overlay.get_result_text(), _owned(scene, east)])
	overlay.confirm_result()
	view.set_hovered_chunk(far)
	print(
		(
			"[after] battle_open=%s owned=%s east_color=%s far_hover=%s"
			% [
				_is_open(scene),
				_owned(scene, east),
				view.get_tile_color(east).to_html(false),
				_one_line(view),
			]
		)
	)

	await _click(scene, _tile_screen_pos(scene, east))
	print("[enter] local=%s active=%s" % [scene.is_local_mode(), scene.world.get_active_hex()])


func _one_line(view: WorldMapView) -> String:
	return view.get_hover_info_text().replace("\n", " / ")


func _is_open(scene: Node) -> bool:
	return scene.battle_overlay.is_open()


func _owned(scene: Node, hex: Hex) -> bool:
	return scene.world.territory.is_owned(hex)


func _tile_screen_pos(scene: Node, hex: Hex) -> Vector2:
	var view: WorldMapView = scene.world_map_view
	var world_pos = view.to_global(view.get_tile_position(hex))
	return scene.get_viewport().get_canvas_transform() * world_pos


func _first_move_card(battle_scene: BattleScene) -> Card:
	for card in battle_scene.card_turn.deck.hand:
		if card.kind == Card.Kind.MOVE and card.cost <= battle_scene.card_turn.energy:
			return card
	return null


# いちばん遠くまで歩けるマス
func _reachable_target(battle: Battle, steps: int) -> Vector2i:
	var reachable = battle.field.reachable(battle.player.position, steps)
	var best = battle.player.position
	for hex in reachable:
		if reachable[hex] > reachable.get(best, 0):
			best = hex
	return best


func _click(scene: Node, pos: Vector2) -> void:
	var motion := InputEventMouseMotion.new()
	motion.position = pos
	motion.global_position = pos
	Input.parse_input_event(motion)
	for pressed in [true, false]:
		var ev := InputEventMouseButton.new()
		ev.button_index = MOUSE_BUTTON_LEFT
		ev.position = pos
		ev.global_position = pos
		ev.pressed = pressed
		Input.parse_input_event(ev)
		Input.flush_buffered_events()
	await scene.get_tree().process_frame
