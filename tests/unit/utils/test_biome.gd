extends GutTest


func test_平原バイオームでは鉄鉱石が採れる():
	assert_eq(Biome.get_biome(Biome.PLAINS).resource_type, "iron_ore")


func test_山岳バイオームでは銅鉱石が採れる():
	assert_eq(Biome.get_biome(Biome.MOUNTAINS).resource_type, "copper_ore")


func test_森林バイオームでは石炭が採れる():
	assert_eq(Biome.get_biome(Biome.FOREST).resource_type, "coal")


func test_砂丘バイオームでは砂が採れる():
	assert_eq(Biome.get_biome(Biome.DESERT).resource_type, "sand")
	assert_eq(Biome.get_biome(Biome.DESERT).display_name, "砂丘")


func test_全バイオームのidを列挙できる():
	assert_eq(Biome.all_ids(), [Biome.PLAINS, Biome.MOUNTAINS, Biome.FOREST, Biome.DESERT])


func test_どのバイオームの資源もアイテムとして登録されている():
	for biome_id in Biome.all_ids():
		var resource_type = Biome.get_biome(biome_id).resource_type
		assert_not_null(ItemDB.get_item(resource_type), resource_type)


func test_バイオームごとにマップ上の色が異なる():
	var colors = {}
	for id in Biome.all_ids():
		colors[Biome.get_biome(id).map_color] = true
	assert_eq(colors.size(), Biome.all_ids().size())


func test_バイオームは表示名を持つ():
	assert_eq(Biome.get_biome(Biome.PLAINS).display_name, "平原")


func test_存在しないidはnullを返す():
	assert_null(Biome.get_biome("unknown"))
