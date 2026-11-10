extends RefCounted
## 詰まったコンベア上のアイテム間隔を測る。
## 配置（アクティブチャンク）: 本線 (-2,0)→(-1,0)→(0,0)→(1,0)→(2,0)（East、(2,0) が終端）
## (0,0) から NE へ分岐 (1,-1)→(2,-2)（(2,-2) が終端）。搬出先が無いので全体が詰まる。
## 各レーン（入口→終端の順に並ぶアイコン）の隣接間隔を、ヘックス中心間距離を 1.0 として出力する。

const CONVEYOR = preload("res://scenes/components/piece/conveyor.tscn")
const FRAMES = 1500


func run(scene: Node) -> void:
	var chunk: Chunk = scene.world.get_active_chunk()
	for q in [-2, -1, 0, 1, 2]:
		chunk.place_piece(CONVEYOR, Hex.new(q, 0), 0)
	chunk.place_piece(CONVEYOR, Hex.new(1, -1), 5)
	chunk.place_piece(CONVEYOR, Hex.new(2, -2), 5)
	var feeder: Piece = chunk.get_piece_at_hex(Hex.new(-2, 0))
	for frame in FRAMES:
		if feeder.get_node("ConveyorLogic").can_accept_item("iron_ore"):
			feeder.add_item("iron_ore", 1)
		await scene.get_tree().process_frame

	var hex_dist = chunk.hex_to_pixel(Hex.new(1, 0)).distance_to(chunk.hex_to_pixel(Hex.new(0, 0)))
	var trunk = [Hex.new(-2, 0), Hex.new(-1, 0), Hex.new(0, 0)]
	_report("E レーン", chunk, trunk + [Hex.new(1, 0), Hex.new(2, 0)], hex_dist)
	_report("NE レーン", chunk, trunk + [Hex.new(1, -1), Hex.new(2, -2)], hex_dist)


func _report(label: String, chunk: Chunk, lane: Array, hex_dist: float) -> void:
	var points: Array = []  # [hex, slot名, 位置]
	for hex in lane:
		var piece = chunk.get_piece_at_hex(hex)
		var logic = piece.get_node("ConveyorLogic")
		# レーン上の進行順に並べる: slot2（後続）→ slot1（先行）
		for slot in [
			["ItemIcon2", logic.get_progress_ratio_2()], ["ItemIcon", logic.get_progress_ratio()]
		]:
			var icon: Sprite2D = piece.get_node("ConveyorVisuals/" + slot[0])
			if icon.visible:
				points.append([hex, "%s(r=%.2f)" % [slot[0], slot[1]], icon.global_position])
	print("== %s ==" % label)
	var prev = null
	for p in points:
		# 分岐元以降で別レーンの出口側にいるアイコンは除外する
		var gap = "" if prev == null else "  gap=%.2f" % (p[2].distance_to(prev) / hex_dist)
		print("  (%d,%d) %s%s" % [p[0].q, p[0].r, p[1], gap])
		prev = p[2]
