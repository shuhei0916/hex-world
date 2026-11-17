extends RefCounted

# ワールドマップの霧と、隣の chunk をその chunk のマスの上で戦って解放する流れを確かめる。
# 実際の入力で: 霧のタイルをクリック（何も起きない）→ 隣のタイルをクリック（地図からは戦わない）
# → 建築の画面でキャラクターを東の辺に立たせて渡るキーを押す（その chunk の上で、入ってきたマスから
# 戦闘が始まる）→ 移動スキルを選んでマスをクリック（主人公が動く）→ 敵を取り除いて勝利
# → 結果を閉じる（同じ画面のまま建築できる。キャラクターは戦い終えたマスに立つ）→ コンベアを置く、
# さらに次の chunk に渡ろうとして撤退する（渡る前のマスに残り、元の chunk の建築の画面に戻る）、
# までを出力する。

const CONVEYOR_SLOT := 0

# 東隣の chunk に面した辺（SE）の、角でないマス
const EAST_EDGE_HEX := Vector2i(2, 3)


func run(scene: Node) -> void:
	var view: WorldMapView = scene.world_map_view
	var east = Vector2i(1, 0)
	var far = Vector2i(2, 0)
	# ヘッドレスの画面は 64x64 で、戦闘のボタンが盤面に重なってクリックを受けてしまうので広げる
	scene.get_window().size = Vector2i(1280, 720)
	scene._enter_world_map_mode()
	await scene.get_tree().process_frame
	for hex in [Vector2i(0, 0), east, far]:
		view.set_hovered_chunk(hex)
		print(
			(
				"[map] %s color=%s hover=%s"
				% [hex, view.get_tile_color(hex).to_html(false), _one_line(view)]
			)
		)

	await _click(scene, _tile_screen_pos(scene, far))
	print("[click fog] %s" % _state(scene))

	await _click(scene, _tile_screen_pos(scene, east))
	print("[click frontier] %s" % _state(scene))

	scene._enter_local_mode()
	await _cross_east(scene)
	print("[cross east] %s player=%s" % [_state(scene), _player(scene)])
	var overlay: BattleOverlay = scene.battle_overlay
	var battle_scene: BattleScene = overlay.battle_scene
	battle_scene.animations_enabled = false
	var battle: Battle = battle_scene.battle
	var chunk: Chunk = scene.world.get_active_chunk()
	print(
		(
			"[battle] stage=%d enemies=%d player=%s cells=%d(chunk %d) walls=%s skills=%s"
			% [
				ChunkBattle.stage_for(east),
				battle.enemies().size(),
				battle.player.position,
				battle.field.cells().size(),
				chunk.get_grid_hex_count(),
				ChunkBattle.walls_of(chunk),
				_bar_texts(battle_scene),
			]
		)
	)
	var player_view = battle_scene.view_of(battle.player)
	print(
		(
			"[overlap] player view at %s, chunk tile at %s"
			% [
				player_view.global_position,
				chunk.to_global(chunk.hex_to_pixel(battle.player.position)),
			]
		)
	)

	# スキルのボタンを押して選び、マスを2回クリックして続けて歩く
	# （ボタンはシグナルで押す。マスは実際のクリックで選ぶ）
	var walk: Skill = battle_scene.skill_turn.skills[0]
	_press(battle_scene, 0)
	print("[select] selected=%s" % [_selected_title(battle_scene)])
	for i in range(2):
		var from = battle.player.position
		var target = _reachable_target(battle, walk.value)
		await _click(scene, _hex_screen_pos(scene, battle_scene, target))
		print(
			(
				"[move] %s -> click %s -> player at %s (energy %d, selected=%s)"
				% [
					from,
					target,
					battle.player.position,
					battle_scene.skill_turn.energy,
					_selected_title(battle_scene),
				]
			)
		)

	# クールダウンのあるスキル（走る）を使うと、しばらく押せなくなる
	_press(battle_scene, 3)
	var dash_target = _reachable_target(battle, battle_scene.skill_turn.skills[3].value)
	await _click(scene, _hex_screen_pos(scene, battle_scene, dash_target))
	print("[cooldown] player at %s skills=%s" % [battle.player.position, _bar_texts(battle_scene)])

	for enemy in battle.enemies():
		battle.field.remove_unit(enemy)
	battle_scene.refresh()
	print(
		(
			"[win] result=%s button=%s owned=%s"
			% [overlay.get_result_text(), overlay.get_confirm_text(), _owned(scene, east)]
		)
	)
	overlay.confirm_result()
	print(
		"[after win] %s owned=%s player=%s" % [_state(scene), _owned(scene, east), _player(scene)]
	)

	# 勝ったあと、同じ画面のままコンベアを置ける
	scene.hud.slot_buttons[CONVEYOR_SLOT].button_pressed = true
	scene.hud.on_slot_pressed(CONVEYOR_SLOT)
	var spot = Vector2i(0, 3)
	scene._hover_local(chunk.hex_to_pixel(spot))
	scene.piece_placer.place_current_piece()
	print("[build] piece at %s: %s" % [spot, chunk.get_piece_at_hex(spot) != null])
	scene.hud.deselect()

	# 次の chunk に渡ろうとして撤退すると、渡る前のマスに残り、元の chunk の建築の画面に戻る
	await _cross_east(scene)
	print("[second battle] %s" % _state(scene))
	overlay.retreat()
	print("[retreat] %s owned=%s player=%s" % [_state(scene), _owned(scene, far), _player(scene)])


func _state(scene: Node) -> String:
	return (
		"battle_open=%s local=%s active=%s hud=%s"
		% [_is_open(scene), scene.is_local_mode(), scene.world.get_active_hex(), scene.hud.visible]
	)


func _player(scene: Node) -> String:
	var player: PlayerCharacter = scene.world.player
	return "%s@%s" % [player.hex, player.chunk_hex]


func _one_line(view: WorldMapView) -> String:
	return view.get_hover_info_text().replace("\n", " / ")


func _is_open(scene: Node) -> bool:
	return scene.battle_overlay.is_open()


func _owned(scene: Node, hex: Vector2i) -> bool:
	return scene.world.territory.is_owned(hex)


func _tile_screen_pos(scene: Node, hex: Vector2i) -> Vector2:
	var view: WorldMapView = scene.world_map_view
	var world_pos = view.to_global(view.get_tile_position(hex))
	return scene.get_viewport().get_canvas_transform() * world_pos


# 戦場のマスの、画面上の位置
func _hex_screen_pos(scene: Node, battle_scene: BattleScene, hex: Vector2i) -> Vector2:
	var world_pos = battle_scene.to_global(Hex.to_pixel(hex, BattleScene.HEX_SIZE))
	return scene.get_viewport().get_canvas_transform() * world_pos


func _selected_title(battle_scene: BattleScene) -> String:
	return battle_scene.selected_skill.title if battle_scene.selected_skill != null else "なし"


func _bar_texts(battle_scene: BattleScene) -> Array:
	return battle_scene.get_node("Hud/SkillBar").get_children().map(
		func(button): return button.text.replace("\n", " / ")
	)


func _press(battle_scene: BattleScene, index: int) -> void:
	battle_scene.get_node("Hud/SkillBar").get_child(index).pressed.emit()


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


# キャラクターを今いる chunk の東の辺に立たせ、実際のキー入力で渡るキーを押す
func _cross_east(scene: Node) -> void:
	scene.world.place_player(scene.world.get_active_hex(), EAST_EDGE_HEX)
	for pressed in [true, false]:
		var ev := InputEventKey.new()
		ev.keycode = Main.CROSS_KEY
		ev.physical_keycode = Main.CROSS_KEY
		ev.pressed = pressed
		Input.parse_input_event(ev)
		Input.flush_buffered_events()
	await scene.get_tree().process_frame
