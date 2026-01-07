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
		grid_manager.create_hex_grid(3)

	func test_ポート接続された隣接ピースにアイテムが移動する():
		# 1. 接続されたピースを配置 (A:出力, B:入力)
		grid_manager.place_piece([Hex.new(0,0)], Hex.new(0,0), Color.WHITE, TetrahexShapes.TetrahexType.TEST_OUT)
		var piece_a = grid_manager.get_piece_at_hex(Hex.new(0,0))
		
		grid_manager.place_piece([Hex.new(0,0)], Hex.new(1,0,-1), Color.WHITE, TetrahexShapes.TetrahexType.TEST_IN)
		var piece_b = grid_manager.get_piece_at_hex(Hex.new(1,0,-1))
		
		# 2. Piece A にアイテムを持たせる
		piece_a.add_item("iron", 1)
		
		# 3. tick を実行
		piece_a.tick(0.1)
		
		# 4. 検証: AからBへ移動していること
		assert_eq(piece_a.get_item_count("iron"), 0, "Piece A should have pushed the item")
		assert_eq(piece_b.get_item_count("iron"), 1, "Piece B should have received the item")

	func test_ポートが接続されていないピースにはアイテムが移動しない():
		# 1. 接続されていないピースを配置 (A:出力, B:出力)
		grid_manager.place_piece([Hex.new(0,0)], Hex.new(0,0), Color.WHITE, TetrahexShapes.TetrahexType.TEST_OUT)
		var piece_a = grid_manager.get_piece_at_hex(Hex.new(0,0))
		
		grid_manager.place_piece([Hex.new(0,0)], Hex.new(1,0,-1), Color.WHITE, TetrahexShapes.TetrahexType.TEST_OUT)
		var piece_b = grid_manager.get_piece_at_hex(Hex.new(1,0,-1))
		
		# 2. Piece A にアイテムを持たせる
		piece_a.add_item("iron", 1)
		
		# 3. tick を実行
		piece_a.tick(0.1)
		
		# 4. 検証: アイテムが移動していないこと
		assert_eq(piece_a.get_item_count("iron"), 1, "Piece A should keep its item")
		assert_eq(piece_b.get_item_count("iron"), 0, "Piece B should not receive the item")

	func test_アイテム移動はクールダウンに基づいて行われる():
		# BARとCHESTは全方向接続なので、このテストはそのままのはず
		grid_manager.place_piece([Hex.new(0,0)], Hex.new(0,0), Color.RED, TetrahexShapes.TetrahexType.BAR)
		var piece_a = grid_manager.get_piece_at_hex(Hex.new(0,0))
		
		grid_manager.place_piece([Hex.new(0,0)], Hex.new(1,0,-1), Color.BLUE, TetrahexShapes.TetrahexType.CHEST)
		var piece_b = grid_manager.get_piece_at_hex(Hex.new(1,0,-1))
		
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
		# BAR, CHESTは全方向接続
		grid_manager.place_piece([Hex.new(0,0)], Hex.new(0,0), Color.RED, TetrahexShapes.TetrahexType.BAR)
		var piece_a = grid_manager.get_piece_at_hex(Hex.new(0,0))
		
		grid_manager.place_piece([Hex.new(0,0)], Hex.new(1,0,-1), Color.BLUE, TetrahexShapes.TetrahexType.CHEST)
		grid_manager.place_piece([Hex.new(0,0)], Hex.new(0,1,-1), Color.BLUE, TetrahexShapes.TetrahexType.CHEST)
		
		piece_a.add_item("iron", 10)
		piece_a.tick(0.1)
		assert_eq(piece_a.get_item_count("iron"), 9, "複数の隣接があっても全体で1個しか減らないべき")

	func test_CHESTはアイテムを勝手に排出しない():
		# CHESTは全方向入力のみで出力はしないように定義を変更する必要がある
		# 現在は全方向入出力なので、このテストは失敗する可能性がある
		grid_manager.place_piece([Hex.new(0,0)], Hex.new(0,0), Color.BLUE, TetrahexShapes.TetrahexType.CHEST)
		var chest_a = grid_manager.get_piece_at_hex(Hex.new(0,0))
		
		grid_manager.place_piece([Hex.new(0,0)], Hex.new(1,0,-1), Color.BLUE, TetrahexShapes.TetrahexType.CHEST)
		var chest_b = grid_manager.get_piece_at_hex(Hex.new(1,0,-1))
		
		chest_a.add_item("iron", 10)
		chest_a.tick(0.1)
		
		assert_eq(chest_a.get_item_count("iron"), 10, "CHESTはアイテムを保持し続けるべき")
		assert_eq(chest_b.get_item_count("iron"), 0, "CHESTはアイテムを排出しないべき")

class TestPiecePorts:
	extends GutTest

	func test_デフォルトでは入出力ポートは空_または定義に従う():
		var piece = Piece.new()
		# タイプが未設定(-1)の場合は空であるべき
		assert_eq(piece.get_input_ports().size(), 0, "Undefined type should have no input ports")
		assert_eq(piece.get_output_ports().size(), 0, "Undefined type should have no output ports")

	func test_ピースタイプに応じたポート定義を取得できる():
		# CHESTタイプでテスト（まだ定義を追加していないので、現時点では空かデフォルト値になるはずだが、
		# 実装後は特定の定義が返ることを期待する。ここでは一旦リストが取得できること自体を確認し、
		# 具体的な中身の検証は実装と合わせる）
		
		var piece = Piece.new()
		var data = {
			"type": TetrahexShapes.TetrahexType.CHEST,
			"hex_coordinates": [Hex.new(0,0)]
		}
		piece.setup(data)
		
		var inputs = piece.get_input_ports()
		var outputs = piece.get_output_ports()
		
		# 現時点ではArrayが返ってくること（nullでないこと）を確認
		assert_not_null(inputs, "Input ports should return an array")
		assert_not_null(outputs, "Output ports should return an array")

class TestPortConnections:
	extends GutTest

	var grid_manager: GridManager
	var piece_a: Piece
	var piece_b: Piece
	var piece_c: Piece

	func before_each():
		grid_manager = GridManager.new()
		add_child_autofree(grid_manager)
		grid_manager.create_hex_grid(3)

		# テスト用のPieceを配置
		# A: (0,0)に配置, TEST_OUT (方向0に出力)
		grid_manager.place_piece([Hex.new(0,0)], Hex.new(0,0), Color.WHITE, TetrahexShapes.TetrahexType.TEST_OUT)
		# B: (1,0)に配置, TEST_IN (方向3に入力)
		grid_manager.place_piece([Hex.new(0,0)], Hex.new(1,0,-1), Color.WHITE, TetrahexShapes.TetrahexType.TEST_IN)
		# C: (2,0)に配置, TEST_OUT_WRONG_DIR (方向1に出力)
		grid_manager.place_piece([Hex.new(0,0)], Hex.new(2,0,-2), Color.WHITE, TetrahexShapes.TetrahexType.TEST_OUT_WRONG_DIR)

		piece_a = grid_manager.get_piece_at_hex(Hex.new(0,0,0))
		piece_b = grid_manager.get_piece_at_hex(Hex.new(1,0,-1))
		piece_c = grid_manager.get_piece_at_hex(Hex.new(2,0,-2))

	func test_ポートが対面かつ正しいペアなら接続可能():
		# piece_a は piece_b の方向0にいる
		# piece_aは(0,0)にいて、bは(1,0,-1)にいる
		# aから見たbの方向は0
		var direction_to_b = 0
		assert_true(piece_a.can_push_to(piece_b, direction_to_b), "A (out) should be able to push to B (in)")
		
		var direction_to_a = 3
		assert_false(piece_b.can_push_to(piece_a, direction_to_a), "B (in) should not be able to push to A (out)")

	func test_ポートが対面でもペアが不正なら接続不可():
		# piece_a と piece_c は両方出力
		var direction_to_c = 0 # piece_aから(1,0,-1)にあるCの方向(これは間違い、Cは(2,0,-2))
		# A(0,0)からC(2,0,-2)への隣接はないが、仮に隣接していたとしてのテスト
		# piece_bをTEST_OUTに差し替える
		grid_manager.remove_piece_at(piece_b.hex_coordinates[0])
		grid_manager.place_piece([Hex.new(0,0)], Hex.new(1,0,-1), Color.WHITE, TetrahexShapes.TetrahexType.TEST_OUT)
		var new_b = grid_manager.get_piece_at_hex(Hex.new(1,0,-1))
		
		assert_false(piece_a.can_push_to(new_b, 0), "Output-to-Output connection should fail")

	func test_ポートがずれている場合は接続不可():
		# piece_a(方向0出力) と piece_c(方向1出力) をテストするが、cは隣接していない
		# bをずれた入力ポートを持つように変更する
		grid_manager.remove_piece_at(piece_b.hex_coordinates[0])
		grid_manager.place_piece([Hex.new(0,0)], Hex.new(1,0,-1), Color.WHITE, TetrahexShapes.TetrahexType.TEST_OUT_WRONG_DIR)
		var wrong_dir_b = grid_manager.get_piece_at_hex(Hex.new(1,0,-1))
		# wrong_dir_bは方向4(左下)に入力を持つとする
		wrong_dir_b.get_input_ports().append({"hex": Hex.new(0,0,0), "direction": 4})
		wrong_dir_b.get_output_ports().clear()
		
		assert_false(piece_a.can_push_to(wrong_dir_b, 0), "Misaligned ports should not connect")

class TestPieceRotation:
	extends GutTest

	func test_ポートはピースの回転に追従する():
		var piece = Piece.new()
		piece.setup({"type": TetrahexShapes.TetrahexType.TEST_OUT})
		add_child_autofree(piece)
		
		# 初期状態: 出力は方向0
		var initial_ports = piece.get_output_ports()
		assert_eq(initial_ports.size(), 1)
		assert_eq(initial_ports[0].direction, 0, "Initial direction should be 0")
		
		# 1回右回転
		piece.rotate_cw()
		var rotated_ports = piece.get_output_ports()
		assert_eq(rotated_ports.size(), 1)
		assert_eq(rotated_ports[0].direction, 1, "Direction should be 1 after one rotation")
		
		# もう1回右回転
		piece.rotate_cw()
		rotated_ports = piece.get_output_ports()
		assert_eq(rotated_ports[0].direction, 2, "Direction should be 2 after two rotations")

		# 6回回転すると元に戻る
		for i in range(4):
			piece.rotate_cw()
		rotated_ports = piece.get_output_ports()
		assert_eq(rotated_ports[0].direction, 0, "Direction should be 0 after 6 rotations")

	func test_複数ヘックスを持つピースのポートも回転する():
		var piece = Piece.new()
		# BARの最初のポートは (-1,0,1) の dir 0 を想定
		piece.setup({"type": TetrahexShapes.TetrahexType.BAR})
		add_child_autofree(piece)

		var initial_port = piece.get_output_ports()[0]
		
		piece.rotate_cw()
		
		var rotated_port = piece.get_output_ports()[0]
		
		# hex(-1,0,1) を右に1回回転させると hex(0,-1,1) になる
		var expected_hex = Hex.rotate_right(initial_port.hex)
		# 方向0を右に1回回転させると方向1になる
		var expected_dir = 1
		
		assert_true(Hex.equals(rotated_port.hex, expected_hex), "Port hex should be rotated")
		assert_eq(rotated_port.direction, expected_dir, "Port direction should be rotated")