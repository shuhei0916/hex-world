extends RefCounted
## 研究の流れを出力する: ハブに納品してレベルを上げる（機械はレベルで自動解放）→
## コンベア高速化を研究して、実ゲームの tick でコンベアが速くなることを確かめる（等速 0.5秒 → 1.5倍で約0.33秒）。

const CONVEYOR = preload("res://scenes/components/piece/conveyor.tscn")
const ASSEMBLER_SLOT := 3


func run(scene: Node) -> void:
	var chunk: Chunk = scene.world.get_active_chunk()
	var hub = chunk.get_piece_at_hex(Hex.new(0, 0))
	_report("開始時", scene)

	hub.add_item("iron_ore", 10)
	hub.add_item("iron_ingot", 20)
	_report("鉄鉱石10・鉄インゴット20を納品", scene)

	scene._handle_key_input(_key(KEY_E))
	print("E キー → 研究パネル visible=%s" % scene.hud.research_panel.visible)

	var before = await _measure_belt_seconds(scene, chunk, Hex.new(3, -3))
	scene.hud.research_panel.get_button("belt_speed_1").pressed.emit()
	var after = await _measure_belt_seconds(scene, chunk, Hex.new(3, -2))
	_report("コンベア高速化 I を研究", scene)
	print("コンベア1マスを運び切る時間: 研究前 %.2f秒 → 研究後 %.2f秒" % [before, after])
	for id in Research.all_ids():
		print("  %s: %s" % [id, scene.hud.research_panel.get_status_text(id)])


# コンベアを1本置いてアイテムを載せ、端まで運び切るのにかかるゲーム内時間を求める。
# 画面なしの起動では処理の重いフレームで経過時間の報告がずれるので、
# フレームごとの進む速さの中央値から換算する。
func _measure_belt_seconds(scene: Node, chunk: Chunk, hex: Hex) -> float:
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
				scene.hud.stock_label.text.replace("\n", " | "),
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
