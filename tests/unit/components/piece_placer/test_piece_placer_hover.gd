# マウスが盤面から外れた（ツールバーの上に乗ったなど）ときのゴーストとクリックの扱い
extends GutTest

const PiecePlacerScene = preload("res://scenes/components/piece_placer/piece_placer.tscn")
const CONVEYOR_SCENE = preload("res://scenes/components/piece/conveyor.tscn")

var piece_placer: PiecePlacer
var chunk: Chunk


func before_each():
	chunk = Chunk.new()
	add_child_autofree(chunk)
	chunk.create_hex_grid(2)
	piece_placer = PiecePlacerScene.instantiate()
	add_child_autofree(piece_placer)
	piece_placer.setup(chunk)


func test_マウスが盤面を離れるとゴーストが消えクリックしても置かない():
	piece_placer.select_piece(CONVEYOR_SCENE)
	piece_placer.update_hover(Vector2(10, 10))
	piece_placer.clear_hover()
	assert_false(piece_placer.cursor_preview.visible)
	assert_false(piece_placer.snap_preview.visible)
	assert_null(piece_placer.current_hovered_hex)
	assert_false(piece_placer.place_current_piece())
	assert_false(chunk.is_occupied(Vector2i(0, 0)))


func test_盤面に戻るとゴーストがまた出る():
	piece_placer.select_piece(CONVEYOR_SCENE)
	piece_placer.clear_hover()
	piece_placer.update_hover(Vector2(10, 10))
	assert_true(piece_placer.cursor_preview.visible)
	assert_true(piece_placer.snap_preview.visible)


func test_ドラッグ中に盤面を離れてもドラッグは続く():
	# 押したまま一瞬ツールバーをかすめても、引いているコンベアを失わない
	piece_placer.select_piece(CONVEYOR_SCENE)
	piece_placer.update_hover(Vector2(10, 10))
	piece_placer.start_drag()
	piece_placer.clear_hover()
	assert_true(piece_placer.is_dragging)
	assert_not_null(piece_placer.current_hovered_hex)
