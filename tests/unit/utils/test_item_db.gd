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


func test_全バイオームの資源がアイコン付きでItemDBに登録されている():
	for biome_id in Biome.all_ids():
		var resource_type = Biome.get_biome(biome_id).resource_type
		var item_def = ItemDB.get_item(resource_type)
		assert_not_null(item_def, resource_type)
		if item_def:
			assert_not_null(item_def.icon, resource_type)


func test_新資源から作るアイテムがアイコン付きで登録されている():
	for id in ["copper_ingot", "steel"]:
		var item_def = ItemDB.get_item(id)
		assert_not_null(item_def, id)
		if item_def:
			assert_not_null(item_def.icon, id)


func test_銅と鋼材から作る中間アイテムがアイコン付きで登録されている():
	for id in ["copper_wire", "steel_beam", "circuit"]:
		var item_def = ItemDB.get_item(id)
		assert_not_null(item_def, id)
		if item_def:
			assert_not_null(item_def.icon, id)


func test_登録済みのアイテムのidを一覧できる():
	assert_true("iron_ore" in ItemDB.all_ids())
	assert_true("circuit" in ItemDB.all_ids())
