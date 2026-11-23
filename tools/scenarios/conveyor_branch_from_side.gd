extends RefCounted
## 不具合の再現: Miner の排出口の前のベルト (-1,-5)（NE から受けて SW へ流す）から、
## 東の (1,-5) へドラッグでコンベアを引くと、(-1,-5) の分岐の見た目がおかしくなる。
##
## 配置: miner_t1 を (0,-7)（排出口 (0,-6) から SW へ）、もう1台を (-1,-6)-(-2,-5)（西へ出す）。
## (-1,-5)→(-1,-4)→(-2,-4) のライン、(1,-5)→(2,-5)→(3,-5) のライン。
## そのあと (-1,-5)→(0,-5)→(1,-5) とドラッグし、前後の (-1,-5) の状態を出力する。

const MINER = preload("res://scenes/components/piece/miner_t1.tscn")
const CONVEYOR = preload("res://scenes/components/piece/conveyor.tscn")


func run(scene: Node) -> void:
	HubGoals.creative_mode = true
	var chunk: Chunk = scene.world.get_active_chunk()
	var placer: PiecePlacer = scene.piece_placer
	placer.reach_center = null
	chunk.place_piece(MINER, Vector2i(0, -7), 0)
	for rot in 6:
		if Hex.from_offset_rotated(Vector2i(0, 1), rot) == Vector2i(-1, 1):
			chunk.place_piece(MINER, Vector2i(-1, -6), rot)
			var m = chunk.get_piece_at_hex(Vector2i(-2, -5))
			print("2台目の Miner rot=%d ports=%s" % [rot, m.get_output_ports()])
			break
	placer.select_piece(CONVEYOR)
	_drag(chunk, placer, [Vector2i(-1, -5), Vector2i(-1, -4), Vector2i(-2, -4)])
	_drag(chunk, placer, [Vector2i(1, -5), Vector2i(2, -5), Vector2i(3, -5)])
	_dump(chunk, "before")
	_drag(chunk, placer, [Vector2i(-1, -5), Vector2i(0, -5), Vector2i(1, -5)])
	_dump(chunk, "after")
	# 見た目の確認用（screenshot.sh）に (-1,-5) の周りを拡大する
	scene.camera.position = chunk.hex_to_pixel(Vector2i(-1, -5))
	var zoom = (
		float(OS.get_environment("BRANCH_ZOOM")) if OS.has_environment("BRANCH_ZOOM") else 2.0
	)
	scene.camera.zoom = Vector2(zoom, zoom)


func _dump(chunk: Chunk, label: String) -> void:
	for hex in [Vector2i(-1, -5), Vector2i(0, -5), Vector2i(-1, -4)]:
		var p: Piece = chunk.get_piece_at_hex(hex)
		if p == null:
			print("[%s] %s なし" % [label, hex])
			continue
		print(
			(
				"[%s] %s out=%s input_direction=%s visuals.inputs=%s connected=%s"
				% [
					label,
					hex,
					p.get_output_ports().map(func(o): return o["direction"]),
					p.input_direction,
					p.get_node("ConveyorVisuals").get_input_directions(),
					p.get_connected_pieces().map(func(c): return chunk.get_base_hex(c)),
				]
			)
		)


func _drag(chunk: Chunk, placer: PiecePlacer, path: Array) -> void:
	placer.start_drag()
	for hex in path:
		placer.update_hover(chunk.hex_to_pixel(hex))
	placer.stop_drag()
