extends GutTest


func test_PieceDataはsceneフィールドを持つ():
	var data = PieceData.get_data(PieceData.Type.MINER)
	assert_true("scene" in data)


func test_MINERはsceneを持つ():
	var data = PieceData.get_data(PieceData.Type.MINER)
	assert_not_null(data.scene)


func test_PieceDataをトップレベルクラスとしてインスタンス化できる():
	var shape: Array[Hex] = [Hex.new(0, 0, 0)]
	var data = PieceData.new(shape, [], "miner")

	assert_not_null(data)
	assert_eq(data.role, "miner")


func test_PieceDataの静的メソッドで定義済みデータを取得できる():
	var data = PieceData.get_data(PieceData.Type.CHEST)
	assert_not_null(data)
	assert_eq(data.role, "storage")
	assert_eq(data.shape.size(), 1)


func test_PieceTypeエニュームが存在する():
	assert_true(PieceData.Type.CONVEYOR == 0)
	assert_true(PieceData.Type.SMELTER == 1)
	assert_true(PieceData.Type.CUTTER == 2)
	assert_true(PieceData.Type.MIXER == 3)
	assert_true(PieceData.Type.PAINTER == 4)
	assert_true(PieceData.Type.MINER == 5)
	assert_true(PieceData.Type.ASSEMBLER == 6)


func test_PieceData構造体が正しく動作する():
	var hex_array: Array[Hex] = [
		Hex.new(0, 0, 0), Hex.new(1, 0, -1), Hex.new(2, 0, -2), Hex.new(3, 0, -3)
	]
	var data = PieceData.new(hex_array, [], "miner")

	assert_eq(data.shape.size(), 4)
	assert_eq(data.color, Color("#F3D283"))


func test_全ての形状データが定義されている():
	assert_true(PieceData.DATA.has(PieceData.Type.CONVEYOR))
	assert_true(PieceData.DATA.has(PieceData.Type.SMELTER))
	assert_true(PieceData.DATA.has(PieceData.Type.CUTTER))
	assert_true(PieceData.DATA.has(PieceData.Type.MIXER))
	assert_true(PieceData.DATA.has(PieceData.Type.PAINTER))
	assert_true(PieceData.DATA.has(PieceData.Type.MINER))
	assert_true(PieceData.DATA.has(PieceData.Type.ASSEMBLER))


func test_CONVEYOR形状が正しく定義されている():
	var data = PieceData.DATA[PieceData.Type.CONVEYOR]
	assert_eq(data.shape.size(), 4)
	assert_true(Hex.equals(data.shape[0], Hex.new(-1, 0, 1)))
	assert_true(Hex.equals(data.shape[1], Hex.new(0, 0, 0)))
	assert_true(Hex.equals(data.shape[2], Hex.new(1, 0, -1)))
	assert_true(Hex.equals(data.shape[3], Hex.new(2, 0, -2)))


func test_CONVEYOR形状はポートを持つ():
	var data = PieceData.DATA[PieceData.Type.CONVEYOR]

	# Inputポートは撤廃されたのでOutputのみチェック
	assert_gt(data.output_ports.size(), 0, "CONVEYOR should have output ports")


func test_SMELTER形状が正しく定義されている():
	var data = PieceData.DATA[PieceData.Type.SMELTER]
	assert_eq(data.shape.size(), 4)
	assert_true(Hex.equals(data.shape[0], Hex.new(-2, 0, 2)))
	assert_true(Hex.equals(data.shape[1], Hex.new(-1, 0, 1)))
	assert_true(Hex.equals(data.shape[2], Hex.new(0, 0, 0)))
	assert_true(Hex.equals(data.shape[3], Hex.new(0, 1, -1)))


func test_全ての形状が適切なhex数を持つ():
	for type in PieceData.Type.values():
		var data = PieceData.DATA[type]
		if type == PieceData.Type.CHEST:
			assert_eq(data.shape.size(), 1, "CHESTは1Hexであるべき")
		else:
			assert_eq(data.shape.size(), 4, "Type %d は4Hexであるべき" % type)


func test_各形状が異なる色を持つ():
	var colors = {}

	for type in PieceData.Type.values():
		var data = PieceData.DATA[type]

		assert_false(colors.has(data.color))

		colors[data.color] = type


func test_PieceDataは文字列の方向指定を整数に変換して保持する():
	var shape: Array[Hex] = [Hex.new(0, 0, 0)]
	var outputs = [{"hex": Hex.new(0, 0, 0), "direction": "E"}]
	var data = PieceData.new(shape, outputs)
	assert_eq(data.output_ports[0].direction, 0, "String direction 'E' should be converted to 0")


func test_PieceDataはroleに基づいて色を自動設定する():
	var shape: Array[Hex] = [Hex.new(0, 0, 0)]

	# Miner -> Orange (#F3D283)
	var miner_data = PieceData.new(shape, [], "miner")
	assert_eq(miner_data.color, Color("#F3D283"), "Miner should be orange")

	# Smelter -> Green (#6AD38D)
	var smelter_data = PieceData.new(shape, [], "smelter")
	assert_eq(smelter_data.color, Color("#6AD38D"), "Smelter should be green")

	# Storage -> Gray (#999999)
	var storage_data = PieceData.new(shape, [], "storage")
	assert_eq(storage_data.color, Color("#999999"), "Storage should be gray")
