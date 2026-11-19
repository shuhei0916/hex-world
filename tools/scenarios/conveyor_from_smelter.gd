extends RefCounted
## 不具合の再現: Smelter の排出口のマスからドラッグを始めて、斜めに曲がるコンベアを引く。
##
## 配置: smelter_t1 を (-3,0) に置く（(-4,0),(-3,0),(-3,1)、排出口は (-3,0) から East）。
## (-3,0)→(-2,0)→(-1,-1)→(0,-2) とドラッグし、(-2,0) のベルトの入力方向と接続を出力する。

const SMELTER = preload("res://scenes/components/piece/smelter_t1.tscn")
const CONVEYOR = preload("res://scenes/components/piece/conveyor.tscn")


func run(scene: Node) -> void:
	var chunk: Chunk = scene.world.get_active_chunk()
	var placer: PiecePlacer = scene.piece_placer
	placer.reach_center = null
	chunk.place_piece(SMELTER, Vector2i(-3, 0), 0)
	placer.select_piece(CONVEYOR)
	placer.start_drag()
	for hex in [Vector2i(-3, 0), Vector2i(-2, 0), Vector2i(-1, -1), Vector2i(0, -2)]:
		placer.update_hover(chunk.hex_to_pixel(hex))
	placer.stop_drag()
	for hex in [Vector2i(-2, 0), Vector2i(-1, -1), Vector2i(0, -2)]:
		var belt: Piece = chunk.get_piece_at_hex(hex)
		var visuals = belt.get_node("ConveyorVisuals")
		print(
			(
				"%s output=%s piece.input_direction=%s visuals.inputs=%s"
				% [hex, belt.get_output_ports()[0]["direction"], belt.input_direction,
				visuals.get_input_directions()]
			)
		)
	var smelter: Piece = chunk.get_piece_at_hex(Vector2i(-3, 0))
	# 排出口ではないマス (-3,1) の東隣に、East 向きのコンベアを置く
	placer.start_drag()
	for hex in [Vector2i(-2, 1), Vector2i(-1, 1)]:
		placer.update_hover(chunk.hex_to_pixel(hex))
	placer.stop_drag()
	var names = smelter.get_connected_pieces().map(func(p): return chunk.get_base_hex(p))
	print("smelter の接続先=%s" % [names])
