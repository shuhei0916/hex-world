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

func test_CHESTタイプはアイテムを生産しない():
	# CHESTタイプとしてセットアップ
	var data = {
		"type": TetrahexShapes.TetrahexType.CHEST,
		"hex_coordinates": [Hex.new(0, 0)]
	}
	piece.setup(data)
	
	# 時間経過
	piece.tick(2.0)
	
	# インベントリは0のままであるべき
	assert_eq(piece.get_item_count("iron"), 0, "CHESTタイプは自動生産を行わないべき")

class TestItemTransport:
	extends GutTest

	var grid_manager: GridManager

	func before_each():
		grid_manager = GridManager.new()
		grid_manager.hex_tile_scene = preload("res://scenes/components/hex_tile/hex_tile.tscn")
		add_child_autofree(grid_manager)
		grid_manager.create_hex_grid(2)

	func test_隣接するピースにアイテムが移動する():
		# 1. ピースを2つ配置
		# Piece A (BAR) at (0,0)
		grid_manager.place_piece([Hex.new(0,0)], Hex.new(0,0), Color.RED, TetrahexShapes.TetrahexType.BAR)
		var piece_a = grid_manager.get_piece_at_hex(Hex.new(0,0))
		
		# Piece B (CHEST) at (1,0)
		grid_manager.place_piece([Hex.new(0,0)], Hex.new(1,0), Color.BLUE, TetrahexShapes.TetrahexType.CHEST)
		var piece_b = grid_manager.get_piece_at_hex(Hex.new(1,0))
		
		# 2. Piece A にアイテムを持たせる
		piece_a.add_item("iron", 1)
		assert_eq(piece_a.get_item_count("iron"), 1)
		assert_eq(piece_b.get_item_count("iron"), 0)
		
		# 3. tick を実行 (移動ロジックが呼ばれるはず)
		piece_a.tick(0.1)
		
		# 4. 検証: AからBへ移動していること
		assert_eq(piece_a.get_item_count("iron"), 0, "Piece Aのインベントリは空になるべき")
		assert_eq(piece_b.get_item_count("iron"), 1, "Piece Bにアイテムが移動しているべき")

	func test_アイテム移動はクールダウンに基づいて行われる():
		# 1. 配置
		grid_manager.place_piece([Hex.new(0,0)], Hex.new(0,0), Color.RED, TetrahexShapes.TetrahexType.BAR)
		var piece_a = grid_manager.get_piece_at_hex(Hex.new(0,0))
		
		grid_manager.place_piece([Hex.new(0,0)], Hex.new(1,0), Color.BLUE, TetrahexShapes.TetrahexType.CHEST)
		var piece_b = grid_manager.get_piece_at_hex(Hex.new(1,0))
		
		# 2. Piece A にアイテムを持たせる
		piece_a.add_item("iron", 10)
		
		# 3. 最初のtick (0.1秒) -> 即時移動する
		piece_a.tick(0.1)
		assert_eq(piece_b.get_item_count("iron"), 1, "最初は即座に移動する")
		
		# 4. さらに0.5秒経過 (クールダウン1.0秒に対して残り0.4秒) -> 移動しない
		piece_a.tick(0.5)
		assert_eq(piece_b.get_item_count("iron"), 1, "クールダウン中は移動しない")
		
		# 5. さらに0.5秒経過 (計1.1秒) -> クールダウン明けて移動する
		piece_a.tick(0.5)
		assert_eq(piece_b.get_item_count("iron"), 2, "クールダウン明けに移動する")

	func test_複数の隣接ピースがあっても全体で1tickにつき1個まで():
		# 1. 配置
		grid_manager.place_piece([Hex.new(0,0)], Hex.new(0,0), Color.RED, TetrahexShapes.TetrahexType.BAR)
		var piece_a = grid_manager.get_piece_at_hex(Hex.new(0,0))
		
		# 2つのチェストを隣接させる
		grid_manager.place_piece([Hex.new(0,0)], Hex.new(1,0), Color.BLUE, TetrahexShapes.TetrahexType.CHEST)
		grid_manager.place_piece([Hex.new(0,0)], Hex.new(0,1), Color.BLUE, TetrahexShapes.TetrahexType.CHEST)
		
		# 2. アイテムを持たせる
		piece_a.add_item("iron", 10)
		
		# 3. tick 実行
		piece_a.tick(0.1)
		
		# 4. 検証: 合計で1個しか減っていないこと
		assert_eq(piece_a.get_item_count("iron"), 9, "複数の隣接があっても全体で1個しか減らないべき")

	func test_CHESTはアイテムを勝手に排出しない():
		# 1. 配置: CHEST(0,0), CHEST(1,0) (隣同士)
		grid_manager.place_piece([Hex.new(0,0)], Hex.new(0,0), Color.BLUE, TetrahexShapes.TetrahexType.CHEST)
		var chest_a = grid_manager.get_piece_at_hex(Hex.new(0,0))
		
		grid_manager.place_piece([Hex.new(0,0)], Hex.new(1,0), Color.BLUE, TetrahexShapes.TetrahexType.CHEST)
		var chest_b = grid_manager.get_piece_at_hex(Hex.new(1,0))
		
		# 2. Chest A にアイテムを持たせる
		chest_a.add_item("iron", 10)
		
		# 3. tick 実行
		chest_a.tick(0.1)
		
		# 4. 検証: アイテムが減っていないこと
		assert_eq(chest_a.get_item_count("iron"), 10, "CHESTはアイテムを保持し続けるべき")
		assert_eq(chest_b.get_item_count("iron"), 0, "CHESTはアイテムを排出しないべき")
