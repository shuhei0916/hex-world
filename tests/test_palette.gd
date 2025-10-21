extends GutTest

const Palette = preload("res://scripts/palette.gd")

func test_パレットはデフォルトで9スロットを持つ():
	var palette = Palette.new()
	assert_eq(palette.get_slot_count(), 9)
