extends GutTest

# TetrahexShapesのテスト
class_name TestTetrahexShapes

func test_TetrahexTypeエニュームが存在する():
	assert_true(TetrahexShapes.TetrahexType.BAR == 0)
	assert_true(TetrahexShapes.TetrahexType.WORM == 1)
	assert_true(TetrahexShapes.TetrahexType.PISTOL == 2)
	assert_true(TetrahexShapes.TetrahexType.PROPELLER == 3)
	assert_true(TetrahexShapes.TetrahexType.ARCH == 4)
	assert_true(TetrahexShapes.TetrahexType.BEE == 5)
	assert_true(TetrahexShapes.TetrahexType.WAVE == 6)

func test_TetrahexDefinition構造体が正しく動作する():
	var hex_array: Array[Hex] = [Hex.new(0, 0, 0), Hex.new(1, 0, -1), Hex.new(2, 0, -2), Hex.new(3, 0, -3)]
	var definition = TetrahexShapes.TetrahexDefinition.new(hex_array, Color.RED)
	
	assert_eq(definition.shape.size(), 4)
	assert_eq(definition.color, Color.RED)

func test_全ての形状データが定義されている():
	assert_true(TetrahexShapes.TetrahexData.definitions.has(TetrahexShapes.TetrahexType.BAR))
	assert_true(TetrahexShapes.TetrahexData.definitions.has(TetrahexShapes.TetrahexType.WORM))
	assert_true(TetrahexShapes.TetrahexData.definitions.has(TetrahexShapes.TetrahexType.PISTOL))
	assert_true(TetrahexShapes.TetrahexData.definitions.has(TetrahexShapes.TetrahexType.PROPELLER))
	assert_true(TetrahexShapes.TetrahexData.definitions.has(TetrahexShapes.TetrahexType.ARCH))
	assert_true(TetrahexShapes.TetrahexData.definitions.has(TetrahexShapes.TetrahexType.BEE))
	assert_true(TetrahexShapes.TetrahexData.definitions.has(TetrahexShapes.TetrahexType.WAVE))

func test_BAR形状が正しく定義されている():
	var bar_def = TetrahexShapes.TetrahexData.definitions[TetrahexShapes.TetrahexType.BAR]
	assert_eq(bar_def.shape.size(), 4)
	assert_true(Hex.equals(bar_def.shape[0], Hex.new(-1, 0, 1)))
	assert_true(Hex.equals(bar_def.shape[1], Hex.new(0, 0, 0)))
	assert_true(Hex.equals(bar_def.shape[2], Hex.new(1, 0, -1)))
	assert_true(Hex.equals(bar_def.shape[3], Hex.new(2, 0, -2)))

func test_WORM形状が正しく定義されている():
	var worm_def = TetrahexShapes.TetrahexData.definitions[TetrahexShapes.TetrahexType.WORM]
	assert_eq(worm_def.shape.size(), 4)
	assert_true(Hex.equals(worm_def.shape[0], Hex.new(-2, 0, 2)))
	assert_true(Hex.equals(worm_def.shape[1], Hex.new(-1, 0, 1)))
	assert_true(Hex.equals(worm_def.shape[2], Hex.new(0, 0, 0)))
	assert_true(Hex.equals(worm_def.shape[3], Hex.new(0, 1, -1)))

func test_全ての形状が適切なhex数を持つ():
	for type in TetrahexShapes.TetrahexType.values():
		var definition = TetrahexShapes.TetrahexData.definitions[type]
		if type == TetrahexShapes.TetrahexType.CHEST:
			assert_eq(definition.shape.size(), 1, "CHESTは1Hexであるべき")
		else:
			assert_eq(definition.shape.size(), 4, "Type %d は4Hexであるべき" % type)

func test_各形状が異なる色を持つ():
	var colors = {}
	for type in TetrahexShapes.TetrahexType.values():
		var definition = TetrahexShapes.TetrahexData.definitions[type]
		assert_false(colors.has(definition.color))
		colors[definition.color] = type
