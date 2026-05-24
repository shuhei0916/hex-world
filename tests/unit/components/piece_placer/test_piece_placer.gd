extends GutTest

const PiecePlacerScene = preload("res://scenes/components/piece_placer/piece_placer.tscn")
const CONVEYOR_SCENE = preload("res://scenes/components/piece/conveyor.tscn")
const CHEST_SCENE = preload("res://scenes/components/piece/chest.tscn")

var piece_placer: PiecePlacer
var chunk: Chunk

# テスト用データ
var shape_arch: Array[Hex]
var shape_arch_rotated: Array[Hex]


func before_all():
	shape_arch = [Hex.new(0, -1, 1), Hex.new(1, -1, 0), Hex.new(1, 0, -1), Hex.new(0, 1, -1)]
	shape_arch_rotated = [
		Hex.new(1, -1, 0), Hex.new(1, 0, -1), Hex.new(0, 1, -1), Hex.new(-1, 1, 0)
	]


func before_each():
	chunk = Chunk.new()
	add_child_autofree(chunk)
	chunk.create_hex_grid(2)

	piece_placer = PiecePlacerScene.instantiate()
	add_child_autofree(piece_placer)

	piece_placer.setup(chunk)


func after_each():
	await get_tree().process_frame


func test_指定したHexに選択中のピースを配置できる():
	piece_placer.select_piece(CONVEYOR_SCENE)
	var target_hex = Hex.new(0, 0)

	var result = piece_placer.place_piece_at_hex(target_hex)
	assert_true(result, "Should return true on success")

	# CONVEYOR shape: (-1,0),(0,0),(1,0),(2,0)
	for offset in piece_placer.current_piece_shape:
		var h = Hex.add(target_hex, offset)
		assert_true(chunk.is_occupied(h))


func test_回転メソッドを呼ぶと現在の形状が更新される():
	piece_placer.current_piece_shape = shape_arch
	piece_placer.rotate_current_piece()
	var current_shape = piece_placer.current_piece_shape

	assert_eq(current_shape.size(), shape_arch_rotated.size())
	for i in range(shape_arch_rotated.size()):
		assert_true(
			Hex.equals(current_shape[i], shape_arch_rotated[i]),
			"Rotated hex at index %d should be correct" % i
		)


func test_cursor_previewはマウス位置に追従する():
	piece_placer.select_piece(CONVEYOR_SCENE)
	piece_placer.update_hover(Vector2(10, 10))
	assert_eq(piece_placer.cursor_preview.position, Vector2(10, 10))


func test_snap_previewはグリッドにスナップする():
	piece_placer.select_piece(CONVEYOR_SCENE)
	piece_placer.update_hover(Vector2(10, 10))
	assert_eq(piece_placer.snap_preview.position, Vector2(0, 0))


func test_cursor_previewにタイルが描画される():
	piece_placer.select_piece(CONVEYOR_SCENE)
	piece_placer.update_hover(Vector2(10, 10))
	assert_gt(piece_placer.cursor_preview.get_child_count(), 0)


func test_snap_previewにタイルが描画される():
	piece_placer.select_piece(CONVEYOR_SCENE)
	piece_placer.update_hover(Vector2(10, 10))
	assert_gt(piece_placer.snap_preview.get_child_count(), 0)


func test_select_pieceでシーンを外部からセットして配置できる():
	piece_placer.select_piece(CHEST_SCENE)

	var target_hex = Hex.new(1, 1)
	var result = piece_placer.place_piece_at_hex(target_hex)

	assert_true(result, "シーンをセットすれば配置できるべき")
	assert_true(chunk.is_occupied(target_hex), "指定した座標が占有されているべき")


func test_出力ポートを持つピースのプレビューに矢印が追加される():
	piece_placer.select_piece(CONVEYOR_SCENE)
	var shape_size = piece_placer.current_piece_shape.size()
	assert_eq(piece_placer.cursor_preview.get_child_count(), shape_size + 1)


func test_出力ポートを持たないピースのプレビューには矢印が追加されない():
	piece_placer.select_piece(CHEST_SCENE)
	var shape_size = piece_placer.current_piece_shape.size()
	assert_eq(piece_placer.cursor_preview.get_child_count(), shape_size)


func test_回転後にプレビューの矢印向きが変わる():
	piece_placer.select_piece(CONVEYOR_SCENE)
	var shape_size = piece_placer.current_piece_shape.size()
	var arrow_before = piece_placer.cursor_preview.get_child(shape_size)
	var rotation_before = arrow_before.rotation
	piece_placer.rotate_current_piece()
	var arrow_after = piece_placer.cursor_preview.get_child(shape_size)
	assert_ne(arrow_after.rotation, rotation_before)


func test_start_dragを呼ぶとis_draggingがtrueになる():
	piece_placer.start_drag()
	assert_true(piece_placer.is_dragging)


func test_stop_dragを呼ぶとis_draggingがfalseになる():
	piece_placer.start_drag()
	piece_placer.stop_drag()
	assert_false(piece_placer.is_dragging)


func test_ドラッグ中にupdate_hoverで新しいヘックスに移動するとピースが設置される():
	piece_placer.select_piece(CONVEYOR_SCENE)
	piece_placer.start_drag()
	var target_hex = Hex.new(0, 0)
	var target_pos = chunk.hex_to_pixel(target_hex)
	piece_placer.update_hover(target_pos)
	assert_true(chunk.is_occupied(target_hex))
