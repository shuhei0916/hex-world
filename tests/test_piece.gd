extends GutTest

func test_setupでタイプと座標を保持できる():
	var piece = Piece.new()
	add_child_autofree(piece)
	
	var dummy_type = TetrahexShapes.TetrahexType.BAR
	var dummy_coords = [Hex.new(0, 0), Hex.new(1, 0)]
	
	var data = {
		"type": dummy_type,
		"hex_coordinates": dummy_coords
	}
	
	# setupメソッドを直接呼び出す
	piece.setup(data)
	
	# プロパティが正しくセットされていることを確認
	assert_eq(piece.piece_type, dummy_type, "piece_type should be set")
	
	assert_not_null(piece.hex_coordinates, "hex_coordinates should not be null")
	assert_eq(piece.hex_coordinates.size(), 2)
	if piece.hex_coordinates.size() > 0:
		assert_true(Hex.equals(piece.hex_coordinates[0], dummy_coords[0]))