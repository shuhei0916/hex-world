extends GutTest

## 研究による速度の強化が、実際のピースの動きに反映されるか

const CONVEYOR = preload("res://scenes/components/piece/conveyor.tscn")
const MINER = preload("res://scenes/components/piece/miner_t1.tscn")
const SMELTER = preload("res://scenes/components/piece/smelter_t1.tscn")

var chunk: Chunk


func before_each():
	HubGoals.reset()
	chunk = Chunk.new()
	add_child_autofree(chunk)


func after_each():
	HubGoals.reset()


func _place(scene: PackedScene, hex: Vector2i) -> Piece:
	chunk.place_piece(scene, hex)
	return chunk.get_piece_at_hex(hex)


## 受け取り続ける末端。届いた個数を数える
class Sink:
	extends RefCounted
	var received := 0

	func can_accept_item(_item_name: String) -> bool:
		return true

	func add_item(_item_name: String, amount: int) -> void:
		received += amount


# 3マスのコンベアの先頭へ詰め込み続け、定常状態で末端に届いた毎分の個数を測る。
# 設計どおりの流量を見るため、ゲームのフレーム（1/60秒）より細かく刻む
# （フレームが粗いと、受け入れの判定がフレーム単位になるぶん少し目減りする）
func _measure_belt_items_per_minute() -> float:
	var line := Chunk.new()
	add_child_autofree(line)
	var belts = []
	for q in [-1, 0, 1]:
		line.place_piece(CONVEYOR, Vector2i(q, 0))
		belts.append(line.get_piece_at_hex(Vector2i(q, 0)))
	var sink = Sink.new()
	belts[-1].set_connected_pieces([sink], [0])
	var steps_per_second := 1000
	var dt = 1.0 / steps_per_second
	var counted_from := 0
	for step in range(steps_per_second * 40):
		if step == steps_per_second * 10:
			counted_from = sink.received  # 最初の10秒（ラインが埋まるまで）は数えない
		if belts[0].can_accept_item("iron_ore"):
			belts[0].add_item("iron_ore", 1)
		for i in range(belts.size() - 1, -1, -1):
			belts[i].tick(dt)
	return (sink.received - counted_from) * 2.0  # 30秒ぶん → 毎分


func test_研究前のコンベアは毎分60個運ぶ():
	assert_almost_eq(_measure_belt_items_per_minute(), 60.0, 2.0)


func test_コンベア高速化は毎分120_240_480個と段階ごとに倍になる():
	HubGoals.researched = {"belt_speed_1": true}
	assert_almost_eq(_measure_belt_items_per_minute(), 120.0, 4.0, "I")
	HubGoals.researched = {"belt_speed_1": true, "belt_speed_2": true}
	assert_almost_eq(_measure_belt_items_per_minute(), 240.0, 8.0, "II")
	HubGoals.researched = {"belt_speed_1": true, "belt_speed_2": true, "belt_speed_3": true}
	assert_almost_eq(_measure_belt_items_per_minute(), 480.0, 16.0, "III")


func test_情報パネルに出すコンベアの流量は実際の流量と同じ():
	assert_almost_eq(HubGoals.get_belt_items_per_minute(), _measure_belt_items_per_minute(), 2.0)
	HubGoals.researched = {"belt_speed_1": true, "belt_speed_2": true, "belt_speed_3": true}
	assert_almost_eq(HubGoals.get_belt_items_per_minute(), _measure_belt_items_per_minute(), 16.0)


func test_研究前はコンベアが半分の時間ではアイテムを運び切らない():
	var conveyor = _place(CONVEYOR, Vector2i(0, 0))
	conveyor.add_item("iron_ore", 1)
	conveyor.tick(TransferBuffer.TRANSFER_TIME * 0.5)
	assert_almost_eq(conveyor.get_node("ConveyorLogic").get_progress_ratio(), 0.5, 0.01)


func test_コンベア高速化2倍では半分の時間でアイテムを運び切る():
	HubGoals.researched = {"belt_speed_1": true, "belt_speed_2": true}
	var conveyor = _place(CONVEYOR, Vector2i(0, 0))
	conveyor.add_item("iron_ore", 1)
	conveyor.tick(TransferBuffer.TRANSFER_TIME * 0.5)
	assert_almost_eq(conveyor.get_node("ConveyorLogic").get_progress_ratio(), 1.0, 0.01)


func test_採掘高速化でMinerの最大速度が上がる():
	chunk.mark_resource_hex(Vector2i(0, 0), "iron_ore")
	var miner = _place(MINER, Vector2i(0, 0))
	assert_almost_eq(miner.crafter.get_max_items_per_minute(), 30.0, 0.01)
	HubGoals.researched = {"mining_speed_1": true}
	assert_almost_eq(miner.crafter.get_max_items_per_minute(), 45.0, 0.01)


func test_採掘高速化はMiner以外の機械を速くしない():
	HubGoals.researched = {"mining_speed_1": true}
	var smelter = _place(SMELTER, Vector2i(0, 0))
	assert_almost_eq(smelter.crafter.get_max_items_per_minute(), 15.0, 0.01)
