extends GutTest

var piece: Piece

func before_each():
	piece = Piece.new()
	add_child_autofree(piece)

func test_setupでタイプと座標を保持できる():
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
	# InventoryLabelをダミーで作成して追加
	var label = Label.new()
	label.name = "InventoryLabel"
	piece.add_child(label)
	
	# アイテム追加
	piece.add_item("iron", 10)
	
	# ラベルのテキストを確認
	assert_true("iron" in label.text, "Label should contain item name")
	assert_true("10" in label.text, "Label should contain item count")

func test_BARタイプは時間経過で鉄を生産する():
	# BARタイプとしてセットアップ
	var data = {
		"type": TetrahexShapes.TetrahexType.BAR,
		"hex_coordinates": []
	}
	piece.setup(data)
	
	# 初期状態
	assert_eq(piece.get_item_count("iron"), 0)
	
	# 0.5秒経過 -> まだ生産されない
	piece.tick(0.5)
	assert_eq(piece.get_item_count("iron"), 0)
	
	# さらに0.5秒経過 (計1.0秒) -> 生産される
	piece.tick(0.5)
	assert_eq(piece.get_item_count("iron"), 1)
	
	# 連続で呼び出し
	piece.tick(1.0)
	assert_eq(piece.get_item_count("iron"), 2)

func test_WORMタイプは鉄を生産しない():
	# WORMタイプとしてセットアップ
	var data = {
		"type": TetrahexShapes.TetrahexType.WORM,
		"hex_coordinates": []
	}
	piece.setup(data)
	
	# 時間経過
	piece.tick(2.0) # 2秒経過
	
	# インベントリは0のままであるべき
	assert_eq(piece.get_item_count("iron"), 0, "WORMタイプは鉄を生産すべきではない")

func test_未初期化のPieceは鉄を生産しない():
	# setupを呼ばない状態（piece_typeは初期値のまま）
	piece.tick(1.0)
	
	# インベントリは0のままであるべき
	assert_eq(piece.get_item_count("iron"), 0, "未初期化のPiece（タイプ不明）が鉄を生産すべきではない")
