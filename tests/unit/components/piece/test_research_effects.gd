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


func _place(scene: PackedScene, hex: Hex) -> Piece:
	chunk.place_piece(scene, hex)
	return chunk.get_piece_at_hex(hex)


func test_研究前はコンベアが半分の時間ではアイテムを運び切らない():
	var conveyor = _place(CONVEYOR, Hex.new(0, 0))
	conveyor.add_item("iron_ore", 1)
	conveyor.tick(TransferBuffer.TRANSFER_TIME * 0.5)
	assert_almost_eq(conveyor.get_node("ConveyorLogic").get_progress_ratio(), 0.5, 0.01)


func test_コンベア高速化2倍では半分の時間でアイテムを運び切る():
	HubGoals.researched = {"belt_speed_1": true, "belt_speed_2": true}
	var conveyor = _place(CONVEYOR, Hex.new(0, 0))
	conveyor.add_item("iron_ore", 1)
	conveyor.tick(TransferBuffer.TRANSFER_TIME * 0.5)
	assert_almost_eq(conveyor.get_node("ConveyorLogic").get_progress_ratio(), 1.0, 0.01)


func test_採掘高速化でMinerの最大速度が上がる():
	chunk.mark_resource_hex(Hex.new(0, 0), "iron_ore")
	var miner = _place(MINER, Hex.new(0, 0))
	assert_almost_eq(miner.crafter.get_max_items_per_minute(), 30.0, 0.01)
	HubGoals.researched = {"mining_speed_1": true}
	assert_almost_eq(miner.crafter.get_max_items_per_minute(), 45.0, 0.01)


func test_採掘高速化はMiner以外の機械を速くしない():
	HubGoals.researched = {"mining_speed_1": true}
	var smelter = _place(SMELTER, Hex.new(0, 0))
	assert_almost_eq(smelter.crafter.get_max_items_per_minute(), 15.0, 0.01)
