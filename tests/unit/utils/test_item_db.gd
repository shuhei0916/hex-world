extends GutTest


func test_アイテム定義を取得できる():
	var item_def = ItemDB.get_item("iron_ore")
	assert_not_null(item_def, "Should retrieve item definition")
	assert_eq(item_def.id, "iron_ore")
	assert_not_null(item_def.icon, "Item should have an icon")


func test_iron_rodがItemDBに登録されている():
	var item_def = ItemDB.get_item("iron_rod")
	assert_not_null(item_def, "iron_rod が登録されているべき")
	assert_eq(item_def.id, "iron_rod")


func test_存在しないアイテムはnullを返す():
	var item_def = ItemDB.get_item("non_existent_item")
	assert_null(item_def, "Should return null for unknown items")
