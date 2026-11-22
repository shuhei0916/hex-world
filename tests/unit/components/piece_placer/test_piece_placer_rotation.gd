# 置くピースの回転と形（形は回転から決まる）
extends GutTest

const PiecePlacerScene = preload("res://scenes/components/piece_placer/piece_placer.tscn")
const MINER_SCENE = preload("res://scenes/components/piece/miner_t1.tscn")

var piece_placer: PiecePlacer


func before_each():
	var chunk = Chunk.new()
	add_child_autofree(chunk)
	piece_placer = PiecePlacerScene.instantiate()
	add_child_autofree(piece_placer)
	piece_placer.setup(chunk)


func _shape_rotated(scene: PackedScene, rotation: int) -> Array[Vector2i]:
	var piece = scene.instantiate()
	var shape: Array[Vector2i] = []
	for offset in piece.piece_shape:
		shape.append(Hex.from_offset_rotated(offset, rotation))
	piece.free()
	return shape


func test_回転させると形も回る():
	piece_placer.select_piece(MINER_SCENE)
	piece_placer.rotate_current_piece()
	assert_eq(piece_placer.current_rotation, 1)
	assert_eq(piece_placer.current_piece_shape, _shape_rotated(MINER_SCENE, 1))


func test_回転を直接決めても形はその回転に従う():
	# 形は回転から決まるので、回転と形を別々に持ってずれることがない
	piece_placer.select_piece(MINER_SCENE)
	piece_placer.current_rotation = 2
	assert_eq(piece_placer.current_piece_shape, _shape_rotated(MINER_SCENE, 2))


func test_別のピースを選ぶと回転は戻る():
	piece_placer.select_piece(MINER_SCENE)
	piece_placer.rotate_current_piece()
	piece_placer.select_piece(MINER_SCENE)
	assert_eq(piece_placer.current_piece_shape, _shape_rotated(MINER_SCENE, 0))
