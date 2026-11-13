extends RefCounted
## PiecePlacer のドラッグで合流を作り、合流先のベルトが両方の入力側から描かれるかを出力する。
##
## 配置（アクティブチャンク）: 本線 (-3,1)→(-2,1)→(-1,1)→(0,1)（East）を引いたあと、
## 別ライン (-1,4)→(-1,3)→(-1,2)（NW 向き）を本線の手前で止め、本線の途中 (-1,1) へ合流させる。
## （本線のマスまで引くと、そのマスのベルトが置き換えられ合流にならない）

const CONVEYOR = preload("res://scenes/components/piece/conveyor.tscn")


func run(scene: Node) -> void:
	var chunk: Chunk = scene.world.get_active_chunk()
	var placer: PiecePlacer = scene.piece_placer
	placer.select_piece(CONVEYOR)
	_drag(chunk, placer, [Hex.new(-3, 1), Hex.new(-2, 1), Hex.new(-1, 1), Hex.new(0, 1)])
	_report(chunk, "本線を引いた直後")
	_drag(chunk, placer, [Hex.new(-1, 4), Hex.new(-1, 3), Hex.new(-1, 2)])
	_report(chunk, "合流ラインを引いた後")


func _drag(chunk: Chunk, placer: PiecePlacer, path: Array) -> void:
	placer.start_drag()
	for hex in path:
		placer.update_hover(chunk.hex_to_pixel(hex))
	placer.stop_drag()


func _report(chunk: Chunk, label: String) -> void:
	var merge: Piece = chunk.get_piece_at_hex(Hex.new(-1, 1))
	var visuals = merge.get_node("ConveyorVisuals")
	var feeder: Piece = chunk.get_piece_at_hex(Hex.new(-1, 2))
	var feeder_connected = feeder != null and merge in feeder.get_connected_pieces()
	print(
		(
			"[%s] (-1,1) output=%s inputs=%s merge_paths=%d / (-1,2)→(-1,1) 接続=%s"
			% [
				label,
				merge.get_output_ports()[0]["direction"],
				visuals.get_input_directions(),
				visuals._merge_paths.size(),
				feeder_connected,
			]
		)
	)
