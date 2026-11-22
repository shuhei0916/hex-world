extends RefCounted
## shapez 風のコンベアの向きの自動調整を、実際のクリック操作で確かめる。
##
## 1. Miner（(3,-5)、排出口は (3,-4) から SW）の排出口の前 (2,-3) に East 向きで1つ置く
##    → 出口は East のまま、NE（Miner）から受ける曲がりになる
## 2. 行き止まりのベルト (-2,1)[East] の NE 隣 (-1,0) に NE 向きのベルトを置く
##    → (-2,1) が NE へ曲がって、新しいベルトへ流し込む
## 3. 入力のないベルト (-2,-1)[East] の NW 隣 (-2,-2) に SE 向きのベルトを置く
##    → (-2,-1) が NW から受ける曲がりになる

const MINER = preload("res://scenes/components/piece/miner_t1.tscn")
const CONVEYOR = preload("res://scenes/components/piece/conveyor.tscn")


func run(scene: Node) -> void:
	var chunk: Chunk = scene.world.get_active_chunk()
	var placer: PiecePlacer = scene.piece_placer
	placer.reach_center = null
	chunk.place_piece(MINER, Vector2i(3, -5), 0)
	placer.select_piece(CONVEYOR)
	_click(placer, Vector2i(2, -3), 0)
	_report(chunk, "1. Miner の前", Vector2i(2, -3))
	_click(placer, Vector2i(-2, 1), 0)
	_click(placer, Vector2i(-1, 0), 1)
	_report(chunk, "2. 行き止まりの横に置いた後", Vector2i(-2, 1))
	_click(placer, Vector2i(-2, -1), 0)
	_click(placer, Vector2i(-2, -2), 5)
	_report(chunk, "3. 入力のないベルトの横に置いた後", Vector2i(-2, -1))


func _click(placer: PiecePlacer, hex: Vector2i, direction: int) -> void:
	placer.current_rotation = (6 - direction) % 6
	placer.place_piece_at_hex(hex)


func _report(chunk: Chunk, label: String, hex: Vector2i) -> void:
	var belt: Piece = chunk.get_piece_at_hex(hex)
	print(
		(
			"[%s] %s output=%s input_direction=%s inputs=%s"
			% [
				label,
				hex,
				belt.get_output_ports()[0]["direction"],
				belt.input_direction,
				belt.get_node("ConveyorVisuals").get_input_directions(),
			]
		)
	)
