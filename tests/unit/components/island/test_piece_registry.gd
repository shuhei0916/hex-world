# gdlint:disable=constant-name
extends GutTest

const PieceRegistry = preload("res://scenes/components/island/piece_registry.gd")


class TestRegisterAndGet:
	extends GutTest

	var registry

	func before_each():
		registry = PieceRegistry.new()

	func test_registerでピースを登録しget_piece_at_hexで取得できる():
		var piece = Node.new()
		add_child_autofree(piece)
		var hex = Hex.new(0, 0)

		registry.register(piece, hex, [hex])

		assert_eq(registry.get_piece_at_hex(hex), piece)

	func test_複数Hexを占有するピースを登録し各Hexから同じピースを取得できる():
		var piece = Node.new()
		add_child_autofree(piece)
		var base = Hex.new(0, 0)
		var hex2 = Hex.new(1, 0)

		registry.register(piece, base, [base, hex2])

		assert_eq(registry.get_piece_at_hex(base), piece)
		assert_eq(registry.get_piece_at_hex(hex2), piece)

	func test_未登録のHexから取得するとnullを返す():
		assert_null(registry.get_piece_at_hex(Hex.new(0, 0)))

	func test_get_base_hexで登録時の起点Hexを返す():
		var piece = Node.new()
		add_child_autofree(piece)
		var base = Hex.new(2, -1)

		registry.register(piece, base, [base])

		assert_eq(registry.get_base_hex(piece), base)

	func test_未登録ピースのget_base_hexはnullを返す():
		var piece = Node.new()
		add_child_autofree(piece)

		assert_null(registry.get_base_hex(piece))


class TestHasPiece:
	extends GutTest

	var registry

	func before_each():
		registry = PieceRegistry.new()

	func test_登録済みHexでhas_piece_atはtrueを返す():
		var piece = Node.new()
		add_child_autofree(piece)
		var hex = Hex.new(1, -1)

		registry.register(piece, hex, [hex])

		assert_true(registry.has_piece_at(hex))

	func test_未登録HexでHas_piece_atはfalseを返す():
		assert_false(registry.has_piece_at(Hex.new(0, 0)))


class TestUnregister:
	extends GutTest

	var registry

	func before_each():
		registry = PieceRegistry.new()

	func test_unregister後にget_piece_at_hexはnullを返す():
		var piece = Node.new()
		add_child_autofree(piece)
		var hex = Hex.new(0, 0)
		registry.register(piece, hex, [hex])

		registry.unregister(piece, [hex])

		assert_null(registry.get_piece_at_hex(hex))

	func test_unregister後にhas_piece_atはfalseを返す():
		var piece = Node.new()
		add_child_autofree(piece)
		var hex = Hex.new(0, 0)
		registry.register(piece, hex, [hex])

		registry.unregister(piece, [hex])

		assert_false(registry.has_piece_at(hex))


class TestGetAllPieces:
	extends GutTest

	var registry

	func before_each():
		registry = PieceRegistry.new()

	func test_1ピースが複数Hexを占有してもget_all_piecesは1件のみ返す():
		var piece = Node.new()
		add_child_autofree(piece)
		var hex1 = Hex.new(0, 0)
		var hex2 = Hex.new(1, 0)
		registry.register(piece, hex1, [hex1, hex2])

		assert_eq(registry.get_all_pieces().size(), 1)

	func test_clear後にget_all_piecesは空を返す():
		var piece = Node.new()
		add_child_autofree(piece)
		var hex = Hex.new(0, 0)
		registry.register(piece, hex, [hex])

		registry.clear()

		assert_eq(registry.get_all_pieces().size(), 0)
