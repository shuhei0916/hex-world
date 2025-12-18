extends GutTest

const PieceScript = preload("res://scenes/components/piece/piece.gd")
const TetrahexShapes = preload("res://scenes/utils/tetrahex_shapes.gd")

func test_setupでタイプと座標を保持できる():
	var piece = PieceScript.new()
	add_child_autofree(piece)
	
	var dummy_type = TetrahexShapes.TetrahexType.BAR
	var dummy_coords = [Hex.new(0, 0), Hex.new(1, 0)]
	
	var data = {
		"type": dummy_type,
		"hex_coordinates": dummy_coords
	}
	
	# setupメソッドを直接呼び出す
	piece.setup(data)
	
	# プロパティが存在し、セットされていることを確認
	# Pieceクラスにこれらのプロパティがまだないので、アクセスエラーになる可能性が高い
	# GUTはスクリプトエラーを検知してテスト失敗としてくれるはず
	assert_eq(piece.get("piece_type"), dummy_type, "piece_type should be set")
	
	var coords = piece.get("hex_coordinates")
	assert_not_null(coords, "hex_coordinates should not be null")
	if coords:
		assert_eq(coords.size(), 2)
		assert_true(Hex.equals(coords[0], dummy_coords[0]))
