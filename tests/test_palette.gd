extends GutTest

var palette: Palette

func before_each():
	palette = Palette.new()
	add_child_autofree(palette)

func test_パレットはデフォルトで9スロットを持つ():
	assert_eq(palette.get_slot_count(), 9)

func test_パレットのアクティブスロットは初期状態で非選択():
	assert_eq(palette.get_active_index(), -1)

func test_選択中のスロットを再度選択すると非選択になる():
	palette.select_slot(2)
	assert_eq(palette.get_active_index(), 2)
	palette.select_slot(2)
	assert_eq(palette.get_active_index(), -1)

func test_数字キー入力で対応スロットがアクティブになる():
	palette.select_slot(2)
	assert_eq(palette.get_active_index(), 2)

func test_無効なインデックス指定ではアクティブスロットが変更されない():
	palette.select_slot(-2)
	assert_eq(palette.get_active_index(), -1)
	
	palette.select_slot(99)
	assert_eq(palette.get_active_index(), -1)

func test_アクティブスロット変更時にハイライトも移動する():
	palette.select_slot(1)
	assert_false(palette.is_slot_highlighted(0))
	assert_true(palette.is_slot_highlighted(1))

func test_スロット1から7には決まったピースが割り当てられている():
	var expected_types = [
		PieceShapes.PieceType.BAR,
		PieceShapes.PieceType.WORM,
		PieceShapes.PieceType.PISTOL,
		PieceShapes.PieceType.PROPELLER,
		PieceShapes.PieceType.ARCH,
		PieceShapes.PieceType.BEE,
		PieceShapes.PieceType.WAVE
	]
	for i in range(expected_types.size()):
		assert_eq(palette.get_piece_type_for_slot(i), expected_types[i], "スロット%dのピースタイプが期待値と異なります" % (i + 1))

func test_スロットピース取得APIで形状データが返る():

	var data = palette.get_piece_data_for_slot(0)

	assert_not_null(data)

	assert_true(data.has("shape"))

	assert_true(data.has("color"))



func test_deselectで選択が解除される():

	palette.select_slot(0)

	assert_eq(palette.get_active_index(), 0)

	

	palette.deselect()

	assert_eq(palette.get_active_index(), -1)

	assert_false(palette.is_slot_highlighted(0), "ハイライトも解除されるべき")
