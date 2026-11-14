extends RefCounted
## 設置コストの流れを出力する: 在庫不足で置けない → ハブに納品 → 設置で在庫が減る → 撤去で全額戻る。

const TARGET := [3, -1]


func run(scene: Node) -> void:
	var chunk: Chunk = scene.world.get_active_chunk()
	var placer: PiecePlacer = scene.piece_placer
	var hex = Hex.new(TARGET[0], TARGET[1])
	HubGoals.gained_rewards["unlock_smelter"] = true
	scene.hud.slot_buttons[2].button_pressed = true
	scene.hud.on_slot_pressed(2)
	placer.select_piece(scene.hud.get_scene_for_slot(2))
	placer.update_hover(chunk.hex_to_pixel(hex))
	_report("Smelter を選択（在庫なし）", scene)
	print("  設置 → %s" % placer.place_current_piece())

	var hub = chunk.get_piece_at_hex(Hex.new(0, 0))
	hub.add_item("iron_ore", 7)
	_report("ハブに Iron Ore を7個納品", scene)
	print("  設置 → %s" % placer.place_current_piece())
	_report("設置後", scene)

	placer.start_delete_drag()
	placer.update_hover(chunk.hex_to_pixel(hex))
	placer.stop_delete_drag()
	_report("撤去後", scene)
	print("  (3,-1) のピース = %s" % chunk.get_piece_at_hex(hex))


func _report(label: String, scene: Node) -> void:
	var hub = scene.world.get_active_chunk().get_piece_at_hex(Hex.new(0, 0)).get_node("Hub")
	print(
		(
			"[%s] %s / パネル=%s / ハブ目標=%d/%d"
			% [
				label,
				scene.hud.stock_label.text.replace("\n", " | "),
				scene.hud.info_panel.description_label.text.replace("\n", " | "),
				hub.received_count,
				hub.goal_count,
			]
		)
	)
