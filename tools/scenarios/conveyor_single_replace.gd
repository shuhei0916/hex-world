extends RefCounted
## 曲がった分岐の先頭を1マスだけ置き直し（クリック相当）、分岐元との接続と入力方向が保たれるかを出力する。
##
## 配置（アクティブチャンク）: 本線 (0,-2)→(-1,-1)→(-2,0)→(-3,1)（SW）を PiecePlacer のドラッグで引き、
## 分岐元 (-2,0) から (-2,1)→(-3,2) の分岐（先頭で曲がる）を引いたあと、(-2,1) を1マスだけ置き直す。

const CONVEYOR = preload("res://scenes/components/piece/conveyor.tscn")


func run(scene: Node) -> void:
	var chunk: Chunk = scene.world.get_active_chunk()
	var placer: PiecePlacer = scene.piece_placer
	placer.select_piece(CONVEYOR)
	_drag(chunk, placer, [Hex.new(0, -2), Hex.new(-1, -1), Hex.new(-2, 0), Hex.new(-3, 1)])
	_drag(chunk, placer, [Hex.new(-2, 0), Hex.new(-2, 1), Hex.new(-3, 2)])
	_report(chunk, "分岐を引いた直後")
	# 実際のクリックと同じ呼び出し順（main.gd: start_drag → place_current_piece → stop_drag）
	placer.update_hover(chunk.hex_to_pixel(Hex.new(-2, 1)))
	placer.start_drag()
	placer.place_current_piece()
	placer.stop_drag()
	await scene.get_tree().process_frame
	_report(chunk, "(-2,1) をクリックで置き直した後")
	# 注: 置き直しで撤去SEが再生中のまま終了するため、終了時に
	# "1 resources still in use at exit"（destroy_building.wav）が出るが無害


func _drag(chunk: Chunk, placer: PiecePlacer, path: Array) -> void:
	placer.start_drag()
	for hex in path:
		placer.update_hover(chunk.hex_to_pixel(hex))
	placer.stop_drag()


func _report(chunk: Chunk, label: String) -> void:
	var origin: Piece = chunk.get_piece_at_hex(Hex.new(-2, 0))
	var head: Piece = chunk.get_piece_at_hex(Hex.new(-2, 1))
	var visuals = head.get_node("ConveyorVisuals")
	print(
		(
			"[scenario] %s: 分岐元→先頭の接続=%s, 先頭のinput_direction=%d, 描画の入力方向=%d, 分岐元の接続数=%d"
			% [
				label,
				head in origin.get_connected_pieces(),
				head.input_direction,
				visuals._input_direction,
				origin.get_connected_pieces().size(),
			]
		)
	)
