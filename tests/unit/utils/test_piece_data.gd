extends GutTest


func test_PieceTypeエニュームが存在する():
	assert_true(PieceData.Type.CONVEYOR == 0)
	assert_true(PieceData.Type.SMELTER == 1)
	assert_true(PieceData.Type.CUTTER == 2)
	assert_true(PieceData.Type.MIXER == 3)
	assert_true(PieceData.Type.PAINTER == 4)
	assert_true(PieceData.Type.MINER == 5)
	assert_true(PieceData.Type.ASSEMBLER == 6)
	assert_true(PieceData.Type.CHEST == 7)


func test_FACILITY_COLORS_BY_TYPEが全Typeの色を持つ():
	for type in PieceData.Type.values():
		assert_true(PieceData.FACILITY_COLORS_BY_TYPE.has(type), "Type %d の色が定義されているべき" % type)


func test_PieceDataをインスタンス化できる():
	var data = PieceData.new()
	assert_not_null(data)


func test_PieceDataにはshapeフィールドが存在しない():
	var data = PieceData.new()
	assert_false("shape" in data, "shape は各ピースシーンに移行済み")


func test_PieceDataにはget_dataメソッドが存在しない():
	assert_false(PieceData.has_method("get_data"), "get_data は削除済み")
