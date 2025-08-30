extends GutTest

# Pieceのテスト
class_name TestPiece

const PieceClass = preload("res://scripts/piece.gd")

func test_Pieceクラスが存在する():
	var piece = PieceClass.new()
	assert_not_null(piece)

func test_形状と色でピースを初期化できる():
	var piece = PieceClass.new()
	var bar_definition = TetrahexShapes.TetrahexData.definitions[TetrahexShapes.TetrahexType.BAR]
	piece.initialize(bar_definition.shape, bar_definition.color)
	assert_eq(piece.shape.size(), 4)

func test_ワールド座標をhex座標に変換できる():
	var piece = PieceClass.new()
	var hex = piece.world_position_to_hex(Vector2(0.0, 0.0))
	assert_not_null(hex)

func test_指定位置にピースを配置可能か判定できる():
	var piece = PieceClass.new()
	var bar_definition = TetrahexShapes.TetrahexData.definitions[TetrahexShapes.TetrahexType.BAR]
	piece.initialize(bar_definition.shape, bar_definition.color)
	
	var test_hex = Hex.new(0, 0)
	for offset in bar_definition.shape:
		var target = Hex.add(test_hex, offset)
		GridManager.register_grid_hex(target)
	
	var can_place = piece.can_place_at_hex(test_hex)
	assert_true(can_place)

func before_each():
	if GridManager:
		GridManager.clear_grid()