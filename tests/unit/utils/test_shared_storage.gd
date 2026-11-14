extends GutTest

var storage: SharedStorage


func before_each():
	storage = SharedStorage.new()


func test_最初は空():
	assert_eq(storage.get_count("iron_ore"), 0)
	assert_eq(storage.get_contents(), {})


func test_入れた分だけ増える():
	storage.add("iron_ore", 2)
	storage.add("iron_ore", 3)
	assert_eq(storage.get_count("iron_ore"), 5)


func test_上限に達するまでは入れられる():
	storage.add("iron_ore", SharedStorage.CAPACITY_PER_ITEM - 1)
	assert_true(storage.can_add("iron_ore"))


func test_上限に達したアイテムは入れられない():
	storage.add("iron_ore", SharedStorage.CAPACITY_PER_ITEM)
	assert_false(storage.can_add("iron_ore"))


func test_上限はアイテムの種類ごとに数える():
	storage.add("iron_ore", SharedStorage.CAPACITY_PER_ITEM)
	assert_true(storage.can_add("coal"))


func test_取り出すと減る():
	storage.add("iron_ore", 3)
	assert_true(storage.take("iron_ore", 1))
	assert_eq(storage.get_count("iron_ore"), 2)


func test_足りないときは取り出せず数も変わらない():
	storage.add("iron_ore", 1)
	assert_false(storage.take("iron_ore", 2))
	assert_eq(storage.get_count("iron_ore"), 1)


func test_使い切ったアイテムは中身の一覧から消える():
	storage.add("iron_ore", 1)
	storage.take("iron_ore", 1)
	assert_eq(storage.get_contents(), {})


func test_中身を保存用に取り出して別の倉庫へ戻せる():
	storage.add("iron_ore", 4)
	storage.add("coal", 2)
	var other = SharedStorage.new()
	# JSON を経ると整数が小数になる
	other.load_contents(JSON.parse_string(JSON.stringify(storage.get_contents())))
	assert_eq(other.get_count("iron_ore"), 4)
	assert_eq(other.get_count("coal"), 2)
