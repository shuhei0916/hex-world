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

func test_インベントリにアイテムを追加できる():
	var piece = Piece.new()
	add_child_autofree(piece)
	
	# 初期状態は0
	assert_eq(piece.get_item_count("iron"), 0, "初期状態のアイテム数は0であるべき")
	
	# 追加
	piece.add_item("iron", 5)
	assert_eq(piece.get_item_count("iron"), 5, "5個追加した後のアイテム数は5であるべき")
	
	# 加算
	piece.add_item("iron", 3)
	assert_eq(piece.get_item_count("iron"), 8, "さらに3個追加した後のアイテム数は8であるべき")
	
	# 別のアイテム
	piece.add_item("copper", 1)
	assert_eq(piece.get_item_count("copper"), 1, "別のアイテム(copper)も正しく追加できるべき")
	assert_eq(piece.get_item_count("iron"), 8, "別のアイテムを追加しても既存のアイテム数は変わらないべき")

func test_アイテム追加時にラベルが更新される():
	var piece = Piece.new()
	add_child_autofree(piece)
	
	# InventoryLabelをダミーで作成して追加
	var label = Label.new()
	label.name = "InventoryLabel"
	piece.add_child(label)
	
	# アイテム追加
	piece.add_item("iron", 10)
	
	# ラベルのテキストを確認
	assert_true("iron" in label.text, "Label should contain item name")
	assert_true("10" in label.text, "Label should contain item count")