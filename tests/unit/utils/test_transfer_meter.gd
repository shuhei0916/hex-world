extends GutTest

## TransferMeter: 渡したアイテムを数え、直近の時間幅から品目ごとの 個/分 を出す

var meter: TransferMeter


func before_each():
	meter = TransferMeter.new()


func test_何も渡していなければ空():
	assert_eq(meter.get_items_per_minute(), {})


func test_時間幅いっぱい経っていれば_幅の中の個数を毎分に直す():
	meter.tick(TransferMeter.WINDOW)
	for i in 15:
		meter.record("iron_ore")
	# 30 秒で 15 個 → 毎分 30 個
	assert_eq(meter.get_items_per_minute(), {"iron_ore": 30.0})


func test_品目ごとに分けて数える():
	meter.tick(TransferMeter.WINDOW)
	meter.record("iron_ore")
	meter.record("copper_ore")
	meter.record("copper_ore")
	assert_eq(meter.get_items_per_minute(), {"iron_ore": 2.0, "copper_ore": 4.0})


func test_時間幅より古い記録は数えない():
	meter.record("iron_ore")
	meter.tick(TransferMeter.WINDOW + 1.0)
	meter.record("copper_ore")
	assert_eq(meter.get_items_per_minute(), {"copper_ore": 2.0})


func test_計り始めてすぐは経った時間で割る():
	meter.tick(10.0)
	meter.record("iron_ore")
	meter.record("iron_ore")
	# 10 秒で 2 個 → 毎分 12 個
	assert_eq(meter.get_items_per_minute(), {"iron_ore": 12.0})


func test_計り始めの1秒未満は1秒とみなす():
	meter.record("iron_ore")
	assert_eq(meter.get_items_per_minute(), {"iron_ore": 60.0})
