extends GutTest

# TetrahexShapesのテスト
class_name TestTetrahexShapes

func test_tetrahex_type_enum_exists():
	# TetrahexTypeのenum値が定義されているか
	assert_true(TetrahexShapes.TetrahexType.BAR == 0)
	assert_true(TetrahexShapes.TetrahexType.WORM == 1)
	assert_true(TetrahexShapes.TetrahexType.PISTOL == 2)
	assert_true(TetrahexShapes.TetrahexType.PROPELLER == 3)
	assert_true(TetrahexShapes.TetrahexType.ARCH == 4)
	assert_true(TetrahexShapes.TetrahexType.BEE == 5)
	assert_true(TetrahexShapes.TetrahexType.WAVE == 6)

func test_tetrahex_definition_structure():
	# TetrahexDefinitionの構造体が正しく動作するか
	var hex_array: Array[Hex] = [Hex.new(0, 0, 0), Hex.new(1, 0, -1), Hex.new(2, 0, -2), Hex.new(3, 0, -3)]
	var definition = TetrahexShapes.TetrahexDefinition.new(hex_array, Color.RED)
	
	assert_eq(definition.shape.size(), 4)
	assert_eq(definition.color, Color.RED)

func test_tetrahex_data_definitions():
	# 全ての形状データが定義されているか
	assert_true(TetrahexShapes.TetrahexData.definitions.has(TetrahexShapes.TetrahexType.BAR))
	assert_true(TetrahexShapes.TetrahexData.definitions.has(TetrahexShapes.TetrahexType.WORM))
	assert_true(TetrahexShapes.TetrahexData.definitions.has(TetrahexShapes.TetrahexType.PISTOL))
	assert_true(TetrahexShapes.TetrahexData.definitions.has(TetrahexShapes.TetrahexType.PROPELLER))
	assert_true(TetrahexShapes.TetrahexData.definitions.has(TetrahexShapes.TetrahexType.ARCH))
	assert_true(TetrahexShapes.TetrahexData.definitions.has(TetrahexShapes.TetrahexType.BEE))
	assert_true(TetrahexShapes.TetrahexData.definitions.has(TetrahexShapes.TetrahexType.WAVE))

func test_bar_shape_definition():
	# BAR形状が正しく定義されているか
	var bar_def = TetrahexShapes.TetrahexData.definitions[TetrahexShapes.TetrahexType.BAR]
	assert_eq(bar_def.shape.size(), 4)
	# 水平に並んだ4つのhex - 正しいs値も確認
	assert_true(Hex.equals(bar_def.shape[0], Hex.new(0, 0, 0)))
	assert_true(Hex.equals(bar_def.shape[1], Hex.new(1, 0, -1)))
	assert_true(Hex.equals(bar_def.shape[2], Hex.new(2, 0, -2)))
	assert_true(Hex.equals(bar_def.shape[3], Hex.new(3, 0, -3)))

func test_worm_shape_definition():
	# WORM形状が正しく定義されているか
	var worm_def = TetrahexShapes.TetrahexData.definitions[TetrahexShapes.TetrahexType.WORM]
	assert_eq(worm_def.shape.size(), 4)
	assert_true(Hex.equals(worm_def.shape[0], Hex.new(0, 0, 0)))
	assert_true(Hex.equals(worm_def.shape[1], Hex.new(1, 0, -1)))
	assert_true(Hex.equals(worm_def.shape[2], Hex.new(2, 0, -2)))
	assert_true(Hex.equals(worm_def.shape[3], Hex.new(2, 1, -3)))

func test_all_shapes_have_four_hexes():
	# 全ての形状が4つのhexを持つか
	for type in TetrahexShapes.TetrahexType.values():
		var definition = TetrahexShapes.TetrahexData.definitions[type]
		assert_eq(definition.shape.size(), 4, "Type %s should have 4 hexes" % type)

func test_shapes_have_different_colors():
	# 各形状が異なる色を持つか
	var colors = {}
	for type in TetrahexShapes.TetrahexType.values():
		var definition = TetrahexShapes.TetrahexData.definitions[type]
		assert_false(colors.has(definition.color), "Color should be unique for each shape type")
		colors[definition.color] = type