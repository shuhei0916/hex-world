extends GutTest

const PiecePlacerScene = preload("res://scenes/components/piece_placer/piece_placer.tscn")

var piece_placer: PiecePlacer
var island: Island

# テスト用データ
var shape_arch: Array[Hex]
var shape_arch_rotated: Array[Hex]


func before_all():
	shape_arch = [Hex.new(0, -1, 1), Hex.new(1, -1, 0), Hex.new(1, 0, -1), Hex.new(0, 1, -1)]
	shape_arch_rotated = [
		Hex.new(1, -1, 0), Hex.new(1, 0, -1), Hex.new(0, 1, -1), Hex.new(-1, 1, 0)
	]


func before_each():
	island = Island.new()
	add_child_autofree(island)
	island.create_hex_grid(2)

	piece_placer = PiecePlacerScene.instantiate()
	add_child_autofree(piece_placer)

	piece_placer.setup(island)


func after_each():
	await get_tree().process_frame


func test_指定したHexに選択中のピースを配置できる():
	var data = PieceData.get_data(PieceData.Type.BAR)
	piece_placer.select_piece(data)
	var target_hex = Hex.new(0, 0)

	var result = piece_placer.place_piece_at_hex(target_hex)
	assert_true(result, "Should return true on success")

	for offset in data.shape:
		var h = Hex.add(target_hex, offset)
		assert_true(island.is_occupied(h))


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


func test_指定した座標のピースを削除できる():
	var target_hex = Hex.new(0, 0)

	var data = PieceData.get_data(PieceData.Type.BAR)
	piece_placer.select_piece(data)
	piece_placer.place_piece_at_hex(target_hex)
	assert_true(island.is_occupied(target_hex), "Hex should be occupied")

	var result = piece_placer.remove_piece_at_hex(target_hex)
	assert_true(result, "Remove should return true")
	assert_false(island.is_occupied(target_hex), "Hex should be empty")

	for offset in data.shape:
		var h = Hex.add(target_hex, offset)
		assert_false(island.is_occupied(h), "All parts of piece should be removed")


func test_cursor_previewはマウス位置に追従する():
	piece_placer.select_piece(PieceData.get_data(PieceData.Type.BAR))
	piece_placer.update_hover(Vector2(10, 10))
	assert_eq(piece_placer.cursor_preview.position, Vector2(10, 10))


func test_snap_previewはグリッドにスナップする():
	piece_placer.select_piece(PieceData.get_data(PieceData.Type.BAR))
	piece_placer.update_hover(Vector2(10, 10))
	assert_eq(piece_placer.snap_preview.position, Vector2(0, 0))


func test_cursor_previewにタイルが描画される():
	piece_placer.select_piece(PieceData.get_data(PieceData.Type.BAR))
	piece_placer.update_hover(Vector2(10, 10))
	assert_gt(piece_placer.cursor_preview.get_child_count(), 0)


func test_snap_previewにタイルが描画される():
	piece_placer.select_piece(PieceData.get_data(PieceData.Type.BAR))
	piece_placer.update_hover(Vector2(10, 10))
	assert_gt(piece_placer.snap_preview.get_child_count(), 0)


func test_select_pieceでPieceDataを外部からセットして配置できる():
	var data = PieceData.get_data(PieceData.Type.CHEST)
	piece_placer.select_piece(data)

	var target_hex = Hex.new(1, 1)
	var result = piece_placer.place_piece_at_hex(target_hex)

	assert_true(result, "PieceDataをセットすれば配置できるべき")
	assert_true(island.is_occupied(target_hex), "指定した座標が占有されているべき")
