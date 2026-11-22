extends RefCounted
## 研究の流れを出力する: ハブに納品してレベルを上げる（機械はレベルで自動解放）→
## 研究ツリーでコンベア高速化のノードを選んで研究し、実ゲームの tick でコンベアが速くなることを確かめる
## （1マス 2.0秒 → 2倍で 1.0秒）。

const CONVEYOR = preload("res://scenes/components/piece/conveyor.tscn")
const ASSEMBLER_SLOT := 3


func run(scene: Node) -> void:
	var chunk: Chunk = scene.world.get_active_chunk()
	var hub = chunk.get_piece_at_hex(Vector2i(0, 0))
	_report("開始時", scene)

	hub.add_item("iron_ore", 10)
	hub.add_item("iron_ingot", 20)
	_report("鉄鉱石10・鉄インゴット20を納品", scene)

	scene._handle_key_input(_key(KEY_E))
	var panel: ResearchPanel = scene.hud.research_panel
	print("E キー → 研究パネル visible=%s / 選ばれている研究=%s" % [panel.visible, panel.get_selected()])

	var before = await _measure_belt_seconds(scene, chunk, Vector2i(3, -3))
	panel.get_node_button("belt_speed_1").pressed.emit()
	panel.research_button.pressed.emit()
	var after = await _measure_belt_seconds(scene, chunk, Vector2i(3, -2))
	_report("コンベア高速化 I を研究", scene)
	print("コンベア1マスを運び切る時間: 研究前 %.2f秒 → 研究後 %.2f秒" % [before, after])
	for id in Research.all_ids():
		var state = HubGoals.research_state_text(id)
		print("  %s: %s" % [id, state if state != "" else "研究できる"])


# コンベアを1本置いてアイテムを載せ、端まで運び切るのにかかるゲーム内時間を求める。
# 画面なしの起動では処理の重いフレームで経過時間の報告がずれるので、
# フレームごとの進む速さの中央値から換算する。
func _measure_belt_seconds(scene: Node, chunk: Chunk, hex: Vector2i) -> float:
	chunk.place_piece(CONVEYOR, hex)
	var logic = chunk.get_piece_at_hex(hex).get_node("ConveyorLogic")
	logic.add_item("iron_ore", 1)
	var speeds := []
	while logic.get_progress_ratio() < 1.0:
		var before = logic.get_progress_ratio()
		await scene.get_tree().process_frame
		var delta = scene.get_process_delta_time()
		if delta > 0.0 and logic.get_progress_ratio() < 1.0:
			speeds.append((logic.get_progress_ratio() - before) / delta)
	speeds.sort()
	return 1.0 / speeds[speeds.size() / 2]


func _report(label: String, scene: Node) -> void:
	print(
		(
			"[%s] Lv%d / %s / 研究ボタン=%s / Assembler のスロット使用可=%s"
			% [
				label,
				HubGoals.level,
				scene.hud.stock_display.get_summary_text(),
				scene.hud.research_button.text,
				not scene.hud.slot_buttons[ASSEMBLER_SLOT].disabled,
			]
		)
	)


func _key(keycode: Key) -> InputEventKey:
	var event = InputEventKey.new()
	event.keycode = keycode
	event.pressed = true
	return event
