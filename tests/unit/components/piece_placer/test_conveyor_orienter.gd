# コンベアの向きの自動調整（shapez の computeOptimalDirectionAndRotationVariantAtTile 相当）
extends GutTest

const CONVEYOR_SCENE = preload("res://scenes/components/piece/conveyor.tscn")

var chunk: Chunk
var orienter: ConveyorOrienter


func before_each():
	chunk = Chunk.new()
	add_child_autofree(chunk)
	chunk.create_hex_grid(3)
	orienter = ConveyorOrienter.new(chunk)


func test_真後ろから入れてくる相手がいれば直進する():
	# (1,0) の西向きのコンベアは (0,0) へ出す → (0,0) は西へ直進
	chunk.place_piece(CONVEYOR_SCENE, Vector2i(1, 0), 3)
	assert_eq(orienter.orientation_at(Vector2i(0, 0), 3), [3, -1])


func test_入れてくる相手が正面にいれば相手から遠ざかる向きに反転する():
	chunk.place_piece(CONVEYOR_SCENE, Vector2i(1, 0), 3)
	assert_eq(orienter.orientation_at(Vector2i(0, 0), 0)[0], 3)


func test_入れてくる相手が横に1つだけなら出口はそのままでその側から受ける():
	# 南東 (0,1) から北西へ出すコンベア（回転4 で出口 NW）は (0,0) へ入れてくる
	chunk.place_piece(CONVEYOR_SCENE, Vector2i(0, 1), 4)
	assert_eq(orienter.orientation_at(Vector2i(0, 0), 0), [0, 5])


func test_入れてくる相手がいなければ手持ちの向きのまま():
	chunk.place_piece(CONVEYOR_SCENE, Vector2i(1, 0), 5)
	assert_eq(orienter.orientation_at(Vector2i(0, 0), 2), [2, -1])


func test_入れてくる相手が2つ以上なら手持ちの向きのまま():
	chunk.place_piece(CONVEYOR_SCENE, Vector2i(1, 0), 3)
	chunk.place_piece(CONVEYOR_SCENE, Vector2i(-1, 0), 0)
	assert_eq(orienter.orientation_at(Vector2i(0, 0), 1), [1, -1])
