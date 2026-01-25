# gdlint:disable=constant-name
extends GutTest

const Types = PieceShapes.PieceType

var piece: Piece


func before_each():
	var scene = load("res://scenes/components/piece/piece.tscn")
	piece = scene.instantiate()
	add_child_autofree(piece)


func test_setupでタイプと座標を保持できる():
	var dummy_type = Types.BAR
	var dummy_coords = [Hex.new(0, 0), Hex.new(1, 0)]

	var data = {"type": dummy_type, "hex_coordinates": dummy_coords}

	# setupメソッドを直接呼び出す
	piece.setup(data)

	# プロパティが正しくセットされていることを確認
	assert_eq(piece.piece_type, dummy_type, "piece_type should be set")
	assert_eq(piece.hex_coordinates.size(), 2)


func test_初期状態のインベントリは空である():
	assert_eq(piece.get_item_count("iron"), 0, "初期状態のアイテム数は0であるべき")


func test_アイテムを追加すると数が加算される():
	# 新規追加
	piece.add_item("iron", 5)
	assert_eq(piece.get_item_count("iron"), 5, "新規追加で数が設定されるべき")

	# 既存への加算
	piece.add_item("iron", 3)
	assert_eq(piece.get_item_count("iron"), 8, "既存アイテムに追加すると数が加算されるべき")


func test_異なる種類のアイテムは個別に管理される():
	piece.add_item("iron", 5)
	piece.add_item("copper", 1)
	assert_eq(piece.get_item_count("copper"), 1, "別のアイテム(copper)も正しく追加できるべき")


func test_異なる種類のアイテムを追加しても既存のアイテム数は変わらない():
	piece.add_item("iron", 5)
	piece.add_item("copper", 1)
	assert_eq(piece.get_item_count("iron"), 5, "別のアイテムを追加しても既存のアイテム数は変わらないべき")


func test_アイテム追加時にラベルが更新される():
	piece.setup({"type": PieceShapes.PieceType.CHEST})
	# CountLabelは詳細モードでのみ表示される仕様に変更されたため
	piece.set_detail_mode(true)
	piece.add_item("iron_ore", 10)

	var label = piece.get_node("StatusIcon/CountLabel")
	assert_true(label.visible, "Count label should be visible")


func test_BARタイプは時間経過で鉄を生産する():
	# BARタイプとしてセットアップ
	var data = {"type": Types.BAR, "hex_coordinates": []}
	piece.setup(data)

	# 初期状態
	assert_eq(piece.get_item_count("iron_ore"), 0)

	# 0.5秒経過 -> まだ生産されない
	piece.tick(0.5)
	assert_eq(piece.get_item_count("iron_ore"), 0)

	# さらに0.5秒経過 (計1.0秒) -> 生産される
	piece.tick(0.5)
	assert_eq(piece.get_item_count("iron_ore"), 1)

	# 連続で呼び出し
	piece.tick(1.0)
	assert_eq(piece.get_item_count("iron_ore"), 2)


func test_WORMタイプは鉄を生産しない():
	# WORMタイプとしてセットアップ
	var data = {"type": Types.WORM, "hex_coordinates": []}
	piece.setup(data)

	# 時間経過
	piece.tick(2.0)  # 2秒経過

	# インベントリは0のままであるべき
	assert_eq(piece.get_item_count("iron"), 0, "WORMタイプは鉄を生産すべきではない")


func test_未初期化のPieceは鉄を生産しない():
	# setupを呼ばない状態（piece_typeは初期値のまま）
	piece.tick(1.0)

	# インベントリは0のままであるべき
	assert_eq(piece.get_item_count("iron"), 0, "未初期化のPiece（タイプ不明）が鉄を生産すべきではない")


func test_CHESTタイプはアイテムを生産しない():
	# CHESTタイプとしてセットアップ
	var data = {"type": Types.CHEST, "hex_coordinates": [Hex.new(0, 0)]}
	piece.setup(data)

	# 時間経過
	piece.tick(2.0)

	# インベントリは0のままであるべき
	assert_eq(piece.get_item_count("iron"), 0, "CHESTタイプは自動生産を行わないべき")


class TestItemTransport:
	extends GutTest

	const Types = PieceShapes.PieceType
	var grid_manager: GridManager

	func before_each():
		grid_manager = GridManager.new()
		grid_manager.hex_tile_scene = preload("res://scenes/components/hex_tile/hex_tile.tscn")
		add_child_autofree(grid_manager)
		grid_manager.create_hex_grid(3)

	func test_ポート接続された隣接ピースにアイテムが移動する():
		# 1. 接続されたピースを配置 (A:出力, B:入力)
		grid_manager.place_piece([Hex.new(0, 0)], Hex.new(0, 0), Color.WHITE, Types.TEST_OUT)
		var piece_a = grid_manager.get_piece_at_hex(Hex.new(0, 0))

		grid_manager.place_piece([Hex.new(0, 0)], Hex.new(1, 0, -1), Color.WHITE, Types.TEST_IN)
		var piece_b = grid_manager.get_piece_at_hex(Hex.new(1, 0, -1))

		# 2. Piece A にアイテムを持たせる
		piece_a.add_to_output("iron", 1)

		# 3. tick を実行
		piece_a.tick(0.1)

		# 4. 検証: AからBへ移動していること
		assert_eq(piece_a.get_item_count("iron"), 0, "Piece A should have pushed the item")
		assert_eq(piece_b.get_item_count("iron"), 1, "Piece B should have received the item")

	func test_ポートが接続されていないピースにはアイテムが移動しない():
		# 1. 接続されていないピースを配置 (A:出力, B:出力)
		grid_manager.place_piece([Hex.new(0, 0)], Hex.new(0, 0), Color.WHITE, Types.TEST_OUT)
		var piece_a = grid_manager.get_piece_at_hex(Hex.new(0, 0))

		grid_manager.place_piece([Hex.new(0, 0)], Hex.new(1, 0, -1), Color.WHITE, Types.TEST_OUT)
		var piece_b = grid_manager.get_piece_at_hex(Hex.new(1, 0, -1))

		# 2. Piece A にアイテムを持たせる
		piece_a.add_item("iron", 1)

		# 3. tick を実行
		piece_a.tick(0.1)

		# 4. 検証: アイテムが移動していないこと
		assert_eq(piece_a.get_item_count("iron"), 1, "Piece A should keep its item")
		assert_eq(piece_b.get_item_count("iron"), 0, "Piece B should not receive the item")

	func test_アイテム移動はクールダウンに基づいて行われる():
		# BARとCHESTは全方向接続なので、このテストはそのままのはず
		grid_manager.place_piece([Hex.new(0, 0)], Hex.new(0, 0), Color.RED, Types.BAR)
		var piece_a = grid_manager.get_piece_at_hex(Hex.new(0, 0))

		grid_manager.place_piece([Hex.new(0, 0)], Hex.new(1, 0, -1), Color.BLUE, Types.CHEST)
		var piece_b = grid_manager.get_piece_at_hex(Hex.new(1, 0, -1))

		# 2. Piece A にアイテムを持たせる
		piece_a.add_to_output("iron", 10)

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
		grid_manager.place_piece([Hex.new(0, 0)], Hex.new(0, 0), Color.RED, Types.BAR)
		var piece_a = grid_manager.get_piece_at_hex(Hex.new(0, 0))

		grid_manager.place_piece([Hex.new(0, 0)], Hex.new(1, 0, -1), Color.BLUE, Types.CHEST)
		grid_manager.place_piece([Hex.new(0, 0)], Hex.new(0, 1, -1), Color.BLUE, Types.CHEST)

		piece_a.add_to_output("iron", 10)
		piece_a.tick(0.1)
		assert_eq(piece_a.get_item_count("iron"), 9, "複数の隣接があっても全体で1個しか減らないべき")

	func test_CHESTはアイテムを勝手に排出しない():
		# CHESTは全方向入力のみで出力はしないように定義を変更する必要がある
		# 現在は全方向入出力なので、このテストは失敗する可能性がある
		grid_manager.place_piece([Hex.new(0, 0)], Hex.new(0, 0), Color.BLUE, Types.CHEST)
		var chest_a = grid_manager.get_piece_at_hex(Hex.new(0, 0))

		grid_manager.place_piece([Hex.new(0, 0)], Hex.new(1, 0, -1), Color.BLUE, Types.CHEST)
		var chest_b = grid_manager.get_piece_at_hex(Hex.new(1, 0, -1))

		chest_a.add_item("iron", 10)
		chest_a.tick(0.1)

		assert_eq(chest_a.get_item_count("iron"), 10, "CHESTはアイテムを保持し続けるべき")
		assert_eq(chest_b.get_item_count("iron"), 0, "CHESTはアイテムを排出しないべき")

	func test_生産ラインが稼働してアイテムが加工・輸送される():
		# 配置:
		# (0,0) BAR (Miner) -> iron_ore
		# (1,0) WORM (Smelter) [in:3, out:0] -> iron_ingot
		# (2,0) PROPELLER (Assembler) [in:3, out:0] -> iron_plate
		# (3,0) CHEST

		# BAR: 出力方向0
		grid_manager.place_piece([Hex.new(0, 0)], Hex.new(0, 0), Color.RED, Types.BAR)
		# WORM: 入力方向3 (左), 出力方向0 (右) -> 回転なしでOK
		grid_manager.place_piece([Hex.new(0, 0)], Hex.new(1, 0), Color.GREEN, Types.WORM)
		# PROPELLER: 入力方向3, 出力方向0 -> 回転なしでOK
		grid_manager.place_piece([Hex.new(0, 0)], Hex.new(2, 0), Color.YELLOW, Types.PROPELLER)
		# CHEST
		grid_manager.place_piece([Hex.new(0, 0)], Hex.new(3, 0), Color.BLUE, Types.CHEST)

		var miner = grid_manager.get_piece_at_hex(Hex.new(0, 0))
		var smelter = grid_manager.get_piece_at_hex(Hex.new(1, 0))
		var assembler = grid_manager.get_piece_at_hex(Hex.new(2, 0))
		var chest = grid_manager.get_piece_at_hex(Hex.new(3, 0))

		# 時間経過シミュレーション
		# 1. 採掘 (1.0s) -> 輸送 (1.0s) -> Smelter到着
		miner.tick(2.1)
		assert_eq(smelter.get_item_count("iron_ore"), 1, "Smelterに鉱石が届く")

		# 2. 精錬 (2.0s) -> 輸送 (1.0s) -> Assembler到着
		smelter.tick(3.1)
		# Smelterのtickを進めると、加工完了 -> 出力ポートへ移動 -> 隣接へPush
		assert_eq(assembler.get_item_count("iron_ingot"), 1, "Assemblerにインゴットが届く")

		# 3. 製作 (3.0s) -> 輸送 (1.0s) -> Chest到着
		assembler.tick(4.1)
		assert_eq(chest.get_item_count("iron_plate"), 1, "Chestに鉄板が届く")

	func test_レシピの材料は輸送されずに加工される():
		# WORM (Smelter) [in:3, out:0] -> iron_ingot
		# 隣接して CHEST を配置 (Smelterの出力方向)

		# WORM: (0,0), 出力方向0
		grid_manager.place_piece([Hex.new(0, 0)], Hex.new(0, 0), Color.GREEN, Types.WORM)
		var smelter = grid_manager.get_piece_at_hex(Hex.new(0, 0))

		# CHEST: (1,0), Smelterの出力先
		grid_manager.place_piece([Hex.new(0, 0)], Hex.new(1, 0), Color.BLUE, Types.CHEST)
		var chest = grid_manager.get_piece_at_hex(Hex.new(1, 0))

		# Smelterに材料(iron_ore)を追加
		smelter.add_item("iron_ore", 1)

		# tickを実行 (輸送が発生しうる時間経過)
		# WORMのレシピは iron_ore -> iron_ingot なので、iron_oreは「材料」
		smelter.tick(0.1)

		# 検証:
		# 1. 加工が開始されていること (Inputから消費され、Processing状態になる)
		assert_gt(smelter.processing_progress, 0.0, "Processing should have started")

		# 2. Chestにはiron_oreが移動していない
		assert_eq(
			chest.get_item_count("iron_ore"), 0, "Ingredients should not be pushed to neighbors"
		)


class TestPiecePorts:
	extends GutTest

	const Types = PieceShapes.PieceType

	func test_デフォルトでは出力ポートは定義に従う():
		var piece = Piece.new()

		# タイプが未設定(-1)の場合は空であるべき

		assert_eq(piece.get_output_ports().size(), 0, "Undefined type should have no output ports")

	func test_ピースタイプに応じた出力ポート定義を取得できる():
		var piece = Piece.new()

		var data = {"type": Types.CHEST, "hex_coordinates": [Hex.new(0, 0)]}

		piece.setup(data)

		var outputs = piece.get_output_ports()

		# 現時点ではArrayが返ってくること（nullでないこと）を確認

		assert_not_null(outputs, "Output ports should return an array")


class TestPortConnections:
	extends GutTest

	const Types = PieceShapes.PieceType

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

		grid_manager.place_piece([Hex.new(0, 0)], Hex.new(0, 0), Color.WHITE, Types.TEST_OUT)

		# B: (1,0)に配置, TEST_IN (現在は単なる空のピース)

		grid_manager.place_piece([Hex.new(0, 0)], Hex.new(1, 0, -1), Color.WHITE, Types.TEST_IN)

		# C: (2,0)に配置, TEST_OUT_WRONG_DIR (方向1に出力)

		grid_manager.place_piece(
			[Hex.new(0, 0)], Hex.new(2, 0, -2), Color.WHITE, Types.TEST_OUT_WRONG_DIR
		)

		piece_a = grid_manager.get_piece_at_hex(Hex.new(0, 0, 0))

		piece_b = grid_manager.get_piece_at_hex(Hex.new(1, 0, -1))

		piece_c = grid_manager.get_piece_at_hex(Hex.new(2, 0, -2))

	func test_出力ポートが相手の方向を向いていれば接続可能():
		# piece_a は piece_b の方向0にいる

		var direction_to_b = 0

		assert_true(
			piece_a.can_push_to(piece_b, direction_to_b), "A (out) should be able to push to B"
		)

	func test_出力ポートが対面でも相手がそこに存在すれば接続可能():
		# piece_a(0,0, out:0) -> B(1,0, out:0)

		# BをTEST_OUTに差し替える

		grid_manager.remove_piece_at(piece_b.hex_coordinates[0])

		grid_manager.place_piece([Hex.new(0, 0)], Hex.new(1, 0, -1), Color.WHITE, Types.TEST_OUT)

		var new_b = grid_manager.get_piece_at_hex(Hex.new(1, 0, -1))

		assert_true(piece_a.can_push_to(new_b, 0), "Should connect even if target also has output")

	func test_入力ポート定義がなくても受け取れる():
		# A: TEST_OUT (方向0出力)

		# B: TEST_IN (現在は入力ポート定義なし)

		assert_true(
			piece_a.can_push_to(piece_b, 0), "Should connect to a piece with no input ports"
		)


class TestPieceRotation:
	extends GutTest

	const Types = PieceShapes.PieceType

	func test_ポートはピースの回転に追従する():
		var piece = Piece.new()

		piece.setup({"type": Types.TEST_OUT})

		add_child_autofree(piece)

		# 初期状態: 出力は方向0

		var initial_ports = piece.get_output_ports()

		assert_eq(initial_ports.size(), 1)

		assert_eq(initial_ports[0].direction, 0, "Initial direction should be 0")

		# 1回右回転

		piece.rotate_cw()

		var rotated_ports = piece.get_output_ports()

		assert_eq(rotated_ports.size(), 1)

		assert_eq(rotated_ports[0].direction, 5, "Direction should be 5 after one rotation (CW)")

		# もう1回右回転

		piece.rotate_cw()

		rotated_ports = piece.get_output_ports()

		assert_eq(rotated_ports[0].direction, 4, "Direction should be 4 after two rotations")

		# 6回回転すると元に戻る

		for i in range(4):
			piece.rotate_cw()

		rotated_ports = piece.get_output_ports()

		assert_eq(rotated_ports[0].direction, 0, "Direction should be 0 after 6 rotations")

	func test_複数ヘックスを持つピースのポートも回転する():
		var piece = Piece.new()

		# BARの出力ポートは (2,0,-2) の dir 0 を想定

		piece.setup({"type": Types.BAR})

		add_child_autofree(piece)

		var initial_port = piece.get_output_ports()[0]  # BARの出力ポート

		piece.rotate_cw()

		var rotated_port = piece.get_output_ports()[0]

		var expected_hex = Hex.rotate_right(initial_port.hex)

		# 方向0 (右) を時計回りに1回回転させると 方向5 (右下) になるはず

		var expected_dir = 5

		assert_true(Hex.equals(rotated_port.hex, expected_hex), "Port hex should be rotated")

		assert_eq(rotated_port.direction, expected_dir, "Port direction should be rotated")


class TestPieceVisuals:
	extends GutTest

	const Types = PieceShapes.PieceType

	func test_ポートの描画パラメータを計算できる():
		var piece = Piece.new()

		# TEST_OUT: (0,0)の方向0(右)に出力

		piece.setup({"type": Types.TEST_OUT})

		add_child_autofree(piece)

		var params = piece.get_port_visual_params()

		assert_eq(params.size(), 1, "Should have one set of params for the port")

		if params.size() > 0:
			var p = params[0]

			assert_true(p.has("position"), "Should have position")

			assert_true(p.has("rotation"), "Should have rotation")

			assert_eq(p.type, "out", "Should only have output ports")

			# 方向0(右)なら、回転は0度(またはそれに相当するラジアン)

			assert_almost_eq(p.rotation, 0.0, 0.01, "Direction 0 should have 0 rotation")

	func test_回転したポートの描画パラメータも正しく計算される():
		var piece = Piece.new()

		piece.setup({"type": Types.TEST_OUT})

		add_child_autofree(piece)

		# 1回回転 -> 方向5 (右下)

		piece.rotate_cw()

		var params = piece.get_port_visual_params()

		if params.size() > 0:
			var p = params[0]

			# 方向5なら 60度 (PI/3 ラジアン)

			assert_almost_eq(p.rotation, PI / 3.0, 0.01, "Direction 5 should have PI/3 rotation")


class TestPieceProcessing:
	extends GutTest

# ... (rest of the file)

	var piece: Piece

	func before_each():
		piece = Piece.new()
		piece.setup({"type": PieceShapes.PieceType.CHEST})  # 暫定的にCHESTを使うが、レシピを設定すれば加工できる想定
		add_child_autofree(piece)

	func test_レシピを設定できる():
		var recipe = Recipe.new("test_recipe", {"ore": 1}, {"ingot": 1}, 1.0)
		piece.set_recipe(recipe)
		assert_eq(piece.current_recipe, recipe)

	func test_材料が足りないときは加工が進まない():
		var recipe = Recipe.new("test_recipe", {"ore": 1}, {"ingot": 1}, 1.0)
		piece.set_recipe(recipe)

		# インベントリは空
		piece.tick(0.5)
		assert_eq(piece.processing_progress, 0.0, "材料がないので進捗は0のまま")
		assert_eq(piece.get_item_count("ingot"), 0)

	func test_材料があるときは加工が進む():
		var recipe = Recipe.new("test_recipe", {"ore": 1}, {"ingot": 1}, 1.0)
		piece.set_recipe(recipe)
		piece.add_item("ore", 1)

		# 0.5秒経過
		piece.tick(0.5)
		assert_gt(piece.processing_progress, 0.0, "加工が進んでいるべき")

		# 加工開始時に消費されるか、完了時に消費されるかは実装次第だが、
		# ここでは「完了時消費」または「開始時に内部バッファへ移動」を想定。
		# 今回はシンプルに「完了時消費」で実装するなら、まだ ore は残っているはず。
		# しかしテストコードを見ると「inputインベントリから減っている」ことを期待しているようなので、
		# 「開始時に消費（加工中バッファへ移動）」モデルを採用する。

		assert_eq(piece.get_item_count("ore"), 0, "材料は加工プロセスに投入される")

	func test_加工が完了すると出力アイテムが生成される():
		var recipe = Recipe.new("test_recipe", {"ore": 1}, {"ingot": 1}, 1.0)
		piece.set_recipe(recipe)
		piece.add_item("ore", 1)

		piece.tick(1.1)  # 完了時間を超える

		assert_eq(piece.get_item_count("ingot"), 1, "成果物が生成されるべき")
		assert_eq(piece.processing_progress, 0.0, "進捗はリセットされる")


class TestSmelter:
	extends GutTest

	const Types = PieceShapes.PieceType
	var piece: Piece

	func before_each():
		piece = Piece.new()
		# WORMタイプとして初期化
		# まだWORMにレシピが紐付いていないので、このテストは失敗するはず
		piece.setup({"type": Types.WORM, "hex_coordinates": [Hex.new(0, 0)]})
		add_child_autofree(piece)

	func test_WORMタイプは自動的に精錬レシピを持つ():
		assert_not_null(piece.current_recipe, "レシピが設定されているべき")
		assert_eq(piece.current_recipe.id, "smelt_iron_ingot", "鉄精錬レシピであるべき")

	func test_WORMタイプは出力ポートを持つ():
		assert_gt(piece.get_output_ports().size(), 0, "出力ポートが必要")


class TestAssembler:
	extends GutTest

	const Types = PieceShapes.PieceType
	var piece: Piece

	func before_each():
		piece = Piece.new()
		piece.setup({"type": Types.PROPELLER, "hex_coordinates": [Hex.new(0, 0)]})
		add_child_autofree(piece)

	func test_PROPELLERタイプは自動的に製作レシピを持つ():
		assert_not_null(piece.current_recipe, "レシピが設定されているべき")
		assert_eq(piece.current_recipe.id, "assemble_iron_plate", "鉄板製作レシピであるべき")

	func test_PROPELLERタイプは出力ポートを持つ():
		assert_gt(piece.get_output_ports().size(), 0, "出力ポートが必要")
