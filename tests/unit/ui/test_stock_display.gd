extends GutTest

## 左上の在庫表示。アイテムごとに「アイコン ×個数」を並べ、消費したときは「-15」を一時的に出す。

var display: StockDisplay


func before_each():
	HubGoals.reset()
	display = StockDisplay.new()
	add_child_autofree(display)


func after_each():
	HubGoals.reset()


func test_在庫が無いときは何も並ばず_なしと表示する():
	assert_eq(display.get_item_ids(), [])
	assert_eq(display.get_summary_text(), "在庫: なし")


func test_在庫のあるアイテムがアイコンと個数で並ぶ():
	HubGoals.add_stock("iron_ore", 5)
	HubGoals.add_stock("coal", 2)
	assert_eq(display.get_item_ids(), ["iron_ore", "coal"])
	assert_eq(display.get_count_text("iron_ore"), "×5")
	assert_eq(display.get_icon("iron_ore"), ItemDB.get_item("iron_ore").icon)


func test_在庫が増えると個数が更新される():
	HubGoals.add_stock("iron_ore", 5)
	HubGoals.add_stock("iron_ore", 3)
	assert_eq(display.get_count_text("iron_ore"), "×8")


func test_要約の文章で在庫の中身が分かる():
	HubGoals.add_stock("iron_ore", 5)
	HubGoals.add_stock("coal", 2)
	assert_eq(display.get_summary_text(), "在庫: Iron Ore ×5、Coal ×2")


func test_消費すると減った数が表示される():
	HubGoals.add_stock("iron_ore", 20)
	HubGoals.pay({"iron_ore": 15})
	assert_eq(display.get_delta_text("iron_ore"), "-15")
	assert_eq(display.get_count_text("iron_ore"), "×5")


func test_増えたときは増減の表示を出さない():
	HubGoals.add_stock("iron_ore", 20)
	assert_eq(display.get_delta_text("iron_ore"), "")
	HubGoals.refund({"iron_ore": 5})
	assert_eq(display.get_delta_text("iron_ore"), "")


func test_消費していないアイテムには増減の表示を出さない():
	HubGoals.add_stock("iron_ore", 20)
	HubGoals.add_stock("coal", 20)
	HubGoals.pay({"iron_ore": 15})
	assert_eq(display.get_delta_text("coal"), "")


func test_減った数の表示はしばらくすると消える():
	HubGoals.add_stock("iron_ore", 20)
	HubGoals.pay({"iron_ore": 15})
	display._process(StockDisplay.DELTA_SECONDS + 0.1)
	assert_eq(display.get_delta_text("iron_ore"), "")


func test_表示が消える前に続けて消費すると合計が表示される():
	HubGoals.add_stock("iron_ore", 20)
	HubGoals.pay({"iron_ore": 5})
	display._process(0.2)
	HubGoals.pay({"iron_ore": 5})
	assert_eq(display.get_delta_text("iron_ore"), "-10")


func test_使い切ったアイテムは減った数の表示が消えるまで残る():
	HubGoals.add_stock("iron_ore", 5)
	HubGoals.pay({"iron_ore": 5})
	assert_eq(display.get_item_ids(), ["iron_ore"])
	assert_eq(display.get_count_text("iron_ore"), "×0")
	display._process(StockDisplay.DELTA_SECONDS + 0.1)
	assert_eq(display.get_item_ids(), [])


func test_やり直しで在庫が消えると表示も空になる():
	HubGoals.add_stock("iron_ore", 5)
	HubGoals.reset()
	display._process(StockDisplay.DELTA_SECONDS + 0.1)
	assert_eq(display.get_item_ids(), [])
