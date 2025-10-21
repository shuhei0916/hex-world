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
