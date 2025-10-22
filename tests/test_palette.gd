extends GutTest

const Palette = preload("res://scripts/palette.gd")

func test_パレットはデフォルトで9スロットを持つ():
	var palette = Palette.new()
	assert_eq(palette.get_slot_count(), 9)

func test_パレットのアクティブスロットは初期状態で0番():
	var palette = Palette.new()
	assert_eq(palette.get_active_index(), 0)

func test_数字キー入力で対応スロットがアクティブになる():
	var palette = Palette.new()
	palette.handle_number_key_input(KEY_3)
	assert_eq(palette.get_active_index(), 2)

func test_無効な数字キー入力ではアクティブスロットがハイライトされたまま():
	var palette = Palette.new()
	palette.handle_number_key_input(KEY_0)
	assert_true(palette.is_slot_highlighted(0))

func test_アクティブスロット変更時にハイライトも移動する():
	var palette = Palette.new()
	palette.handle_number_key_input(KEY_2)
	assert_false(palette.is_slot_highlighted(0))
	assert_true(palette.is_slot_highlighted(1))

func test_スロット1から7には決まったピースが割り当てられている():
	var palette = Palette.new()
	var expected_types = [
		TetrahexShapes.TetrahexType.BAR,
		TetrahexShapes.TetrahexType.WORM,
		TetrahexShapes.TetrahexType.PISTOL,
		TetrahexShapes.TetrahexType.PROPELLER,
		TetrahexShapes.TetrahexType.ARCH,
		TetrahexShapes.TetrahexType.BEE,
		TetrahexShapes.TetrahexType.WAVE
	]
	for i in range(expected_types.size()):
		assert_eq(palette.get_piece_type_for_slot(i), expected_types[i], "スロット%dのピースタイプが期待値と異なります" % (i + 1))

func test_スロットピース取得APIで形状データが返る():
	var palette = Palette.new()
	var data = palette.get_piece_data_for_slot(0)
	assert_not_null(data)
	assert_true(data.has("shape"))
	assert_true(data.has("color"))
