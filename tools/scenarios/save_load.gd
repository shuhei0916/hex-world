extends RefCounted
## 工場を組んでセーブし、別の Main を起動して同じ状態に戻るかを出力する。
## （ツールは専用のセーブファイルを使うので、本物のセーブデータには触れない）
##
## 配置: chunk(0,0) に Miner→コンベア2本、隣の chunk(1,0) にも入ってコンベアを1本置く。

const MAIN = preload("res://scenes/main/main.tscn")
const CONVEYOR = preload("res://scenes/components/piece/conveyor.tscn")
const MINER = preload("res://scenes/components/piece/miner_t1.tscn")


func run(scene: Node) -> void:
	var chunk: Chunk = scene.world.get_active_chunk()
	var deposit = _first_deposit(chunk)
	chunk.place_piece(MINER, deposit)
	chunk.place_piece(CONVEYOR, Hex.new(3, 1))
	chunk.place_piece(CONVEYOR, Hex.new(4, 1))
	HubGoals.advance_level()
	scene._handle_world_map_chunk_selected(Hex.new(1, 0))
	scene.world.get_active_chunk().place_piece(CONVEYOR, Hex.new(0, 2), 2)
	_report("セーブ前", scene)
	print("save_game() = %s / file exists = %s" % [scene.save_game(), SaveGame.exists()])

	HubGoals.reset()
	var loaded = MAIN.instantiate()
	scene.get_tree().root.add_child(loaded)
	await scene.get_tree().process_frame
	_report("ロード後", loaded)
	var a = loaded.world.get_chunk(Hex.new(0, 0)).get_piece_at_hex(Hex.new(3, 1))
	var b = loaded.world.get_chunk(Hex.new(0, 0)).get_piece_at_hex(Hex.new(4, 1))
	print("ロード後 コンベア(3,1)→(4,1) 接続=%s" % (b in a.get_connected_pieces()))
	await scene.get_tree().create_timer(3.0).timeout
	var miner = loaded.world.get_chunk(Hex.new(0, 0)).get_piece_at_hex(deposit)
	print("ロード後3秒 miner recipe=%s" % [miner.current_recipe.outputs])
	loaded.queue_free()


func _report(label: String, main: Node) -> void:
	var lines := []
	for chunk_hex in main.world.get_chunk_hexes():
		var chunk: Chunk = main.world.get_chunk(chunk_hex)
		var pieces := []
		for piece in chunk.get_all_pieces():
			var hex = chunk.get_base_hex(piece)
			pieces.append("%s@(%d,%d)r%d" % [piece.piece_name, hex.q, hex.r, piece.rotation_state])
		pieces.sort()
		var deposits := []
		for hex in chunk.get_all_hexes():
			if chunk.get_hex_resource(hex) != "":
				deposits.append("(%d,%d)" % [hex.q, hex.r])
		lines.append("  chunk%s pieces=%s deposits=%s" % [chunk_hex, pieces, deposits])
	var active = main.world.get_active_hex()
	var smelter_locked = main.hud.slot_buttons[2].disabled
	print(
		(
			"[%s] active=(%d,%d) level=%d smelter_locked=%s\n%s"
			% [label, active.q, active.r, HubGoals.level, smelter_locked, "\n".join(lines)]
		)
	)


func _first_deposit(chunk: Chunk) -> Hex:
	for hex in chunk.get_all_hexes():
		if chunk.get_hex_resource(hex) != "":
			return hex
	return null
