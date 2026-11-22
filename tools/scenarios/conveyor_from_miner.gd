extends RefCounted
## 不具合の再現: 隣を別のラインが通っている場所で、Miner の排出口からドラッグを始めてコンベアを引く。
##
## 配置: miner_t1 を (2,-5) と (3,-5) に置く（それぞれ (2,-4)・(3,-4) の排出口から SW へ出す）。
## (2,-4) の先は (1,-3)→(0,-2) と南西へ流れるライン。
## (3,-4)→(2,-3)→(3,-3)→(4,-3) とドラッグし、(2,-3) のベルトの入力方向と (1,-3) の接続先を出力する。

const MINER = preload("res://scenes/components/piece/miner_t1.tscn")
const CONVEYOR = preload("res://scenes/components/piece/conveyor.tscn")


func run(scene: Node) -> void:
	var chunk: Chunk = scene.world.get_active_chunk()
	var placer: PiecePlacer = scene.piece_placer
	placer.reach_center = null
	chunk.place_piece(MINER, Vector2i(2, -5), 0)
	chunk.place_piece(MINER, Vector2i(3, -5), 0)
	placer.select_piece(CONVEYOR)
	_drag(chunk, placer, [Vector2i(2, -4), Vector2i(1, -3), Vector2i(0, -2)])
	_drag(chunk, placer, [Vector2i(3, -4), Vector2i(2, -3), Vector2i(3, -3), Vector2i(4, -3)])
	var head: Piece = chunk.get_piece_at_hex(Vector2i(2, -3))
	print(
		(
			"(2,-3) output=%s piece.input_direction=%s visuals.inputs=%s"
			% [
				head.get_output_ports()[0]["direction"],
				head.input_direction,
				head.get_node("ConveyorVisuals").get_input_directions(),
			]
		)
	)
	var side: Piece = chunk.get_piece_at_hex(Vector2i(1, -3))
	var targets = side.get_connected_pieces().map(func(p): return chunk.get_base_hex(p))
	print("(1,-3) の接続先=%s" % [targets])


func _drag(chunk: Chunk, placer: PiecePlacer, path: Array) -> void:
	placer.start_drag()
	for hex in path:
		placer.update_hover(chunk.hex_to_pixel(hex))
	placer.stop_drag()
