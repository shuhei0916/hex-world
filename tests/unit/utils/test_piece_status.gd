extends GutTest

const CONVEYOR = preload("res://scenes/components/piece/conveyor.tscn")
const MINER = preload("res://scenes/components/piece/miner_t1.tscn")
const SMELTER = preload("res://scenes/components/piece/smelter_t1.tscn")
const MIXER = preload("res://scenes/components/piece/mixer_t1.tscn")
const SENDER = preload("res://scenes/components/piece/sender.tscn")

var chunk: Chunk


func before_each():
	chunk = Chunk.new()
	add_child_autofree(chunk)


func _place(scene: PackedScene, hex: Hex, rotation: int = 0) -> Piece:
	chunk.place_piece(scene, hex, rotation)
	return chunk.get_piece_at_hex(hex)


# 出力ポートの先のマスにコンベアを置いて、機械の搬出先にする
func _place_output_conveyor(machine: Piece) -> Piece:
	var port = machine.get_output_ports()[0]
	var port_hex = Hex.add(chunk.get_base_hex(machine), port["hex"])
	return _place(CONVEYOR, Hex.neighbor(port_hex, port["direction"]))


func _tick(piece: Piece, seconds: float) -> void:
	for i in int(seconds * 10):
		piece.tick(0.1)


class TestMachineState:
	extends "res://tests/unit/utils/test_piece_status.gd"

	func test_材料が無い機械は材料待ち():
		var smelter = _place(SMELTER, Hex.new(0, 0))
		assert_eq(PieceStatus.state_of(smelter), PieceStatus.State.WAITING_INPUT)

	func test_材料待ちでは足りない材料の名前が分かる():
		var mixer = _place(MIXER, Hex.new(0, 0))
		mixer.add_item("coal", 1)
		assert_eq(PieceStatus.missing_inputs(mixer), ["iron_ingot"])

	func test_加工中の機械は稼働中():
		var smelter = _place(SMELTER, Hex.new(0, 0))
		smelter.add_item("iron_ore", 1)
		_tick(smelter, 0.5)
		assert_eq(PieceStatus.state_of(smelter), PieceStatus.State.WORKING)

	func test_完成品を出す先が無い機械は搬出先なし():
		var smelter = _place(SMELTER, Hex.new(0, 0))
		smelter.add_item("iron_ore", 1)
		_tick(smelter, 10.0)
		assert_eq(PieceStatus.state_of(smelter), PieceStatus.State.NO_OUTPUT_TARGET)

	func test_搬出先が受け取れず完成品が残っている機械は搬出詰まり():
		var smelter = _place(SMELTER, Hex.new(0, 0))
		var conveyor = _place_output_conveyor(smelter)
		assert_true(conveyor in smelter.get_connected_pieces(), "前提: 搬出先につながっている")
		# 行き止まりのコンベアを満杯にしてから完成品を作る
		smelter.add_to_output("iron_ingot", 1)
		for i in 100:
			smelter.tick(0.1)
			conveyor.tick(0.1)
			if smelter.get_item_count("iron_ingot") == 0:
				smelter.add_to_output("iron_ingot", 1)
		assert_eq(PieceStatus.state_of(smelter), PieceStatus.State.OUTPUT_BLOCKED)

	func test_鉱床の無い場所のMinerは鉱床なし():
		var miner = _place(MINER, Hex.new(0, 0))
		assert_eq(PieceStatus.state_of(miner), PieceStatus.State.NO_DEPOSIT)

	func test_鉱床の上で搬出先のあるMinerは稼働中():
		chunk.mark_resource_hex(Hex.new(0, 0), "iron_ore")
		var miner = _place(MINER, Hex.new(0, 0))
		_place_output_conveyor(miner)
		_tick(miner, 0.5)
		assert_eq(PieceStatus.state_of(miner), PieceStatus.State.WORKING)


class TestMeasuredRate:
	extends "res://tests/unit/utils/test_piece_status.gd"

	func test_何も作っていない機械の実績は0():
		var smelter = _place(SMELTER, Hex.new(0, 0))
		_tick(smelter, 5.0)
		assert_eq(smelter.crafter.get_measured_items_per_minute(), 0.0)

	func test_止まらず動く機械の実績は最大速度に近い():
		chunk.mark_resource_hex(Hex.new(0, 0), "iron_ore")
		var miner = _place(MINER, Hex.new(0, 0))
		var conveyor = _place_output_conveyor(miner)
		for i in 600:
			miner.tick(0.1)
			# 行き止まりのコンベアが詰まらないよう、運ばれてきた分は取り除く
			conveyor.get_node("ConveyorLogic")._buffer.clear()
		var max_rate = miner.crafter.get_max_items_per_minute()
		assert_almost_eq(miner.crafter.get_measured_items_per_minute(), max_rate, max_rate * 0.2)

	func test_材料が途切れると実績は時間とともに下がる():
		var smelter = _place(SMELTER, Hex.new(0, 0))
		_place_output_conveyor(smelter)
		smelter.add_item("iron_ore", 1)
		_tick(smelter, 6.0)
		var early = smelter.crafter.get_measured_items_per_minute()
		_tick(smelter, 60.0)
		assert_gt(early, 0.0)
		assert_eq(smelter.crafter.get_measured_items_per_minute(), 0.0)

	func test_最大速度は鉱床の濃さと機械の倍率を反映する():
		chunk.mark_resource_hex(Hex.new(0, 0), "iron_ore")
		var miner = _place(MINER, Hex.new(0, 0))
		# t1 は加工時間2倍: 60 / (1.0s × 2) = 30/分
		assert_almost_eq(miner.crafter.get_max_items_per_minute(), 30.0, 0.01)


class TestDescription:
	extends "res://tests/unit/utils/test_piece_status.gd"

	func test_材料待ちの機械は足りない材料を表示する():
		var smelter = _place(SMELTER, Hex.new(0, 0))
		assert_string_contains(PieceStatus.describe(smelter), "材料待ち（Iron Ore が足りない）")

	func test_機械は作っているものを表示する():
		var smelter = _place(SMELTER, Hex.new(0, 0))
		assert_string_contains(PieceStatus.describe(smelter), "生産: Iron Ingot")

	func test_搬出先の無い機械はその旨を表示する():
		var smelter = _place(SMELTER, Hex.new(0, 0))
		smelter.add_item("iron_ore", 1)
		_tick(smelter, 10.0)
		assert_string_contains(PieceStatus.describe(smelter), "搬出先がない")

	func test_鉱床の無いMinerはその旨を表示する():
		var miner = _place(MINER, Hex.new(0, 0))
		assert_string_contains(PieceStatus.describe(miner), "鉱床がない")

	func test_機械の実績と最大速度を表示する():
		var smelter = _place(SMELTER, Hex.new(0, 0))
		assert_eq(PieceStatus.rate_text(smelter), "実績: 0/分（最大 15/分）")

	func test_空のコンベアは空と表示する():
		var conveyor = _place(CONVEYOR, Hex.new(0, 0))
		assert_string_contains(PieceStatus.describe(conveyor), "運んでいるもの: なし")

	func test_コンベアは運んでいるアイテムを表示する():
		var conveyor = _place(CONVEYOR, Hex.new(0, 0))
		conveyor.add_item("coal", 1)
		assert_string_contains(PieceStatus.describe(conveyor), "運んでいるもの: Coal")

	func test_行き止まりのコンベアは搬出先がないと表示する():
		var conveyor = _place(CONVEYOR, Hex.new(0, 0))
		assert_string_contains(PieceStatus.describe(conveyor), "搬出先がない")

	func test_コンベアには実績を表示しない():
		var conveyor = _place(CONVEYOR, Hex.new(0, 0))
		assert_eq(PieceStatus.rate_text(conveyor), "")

	func test_ハブは目標の進み具合を表示する():
		chunk.place_hub("iron_ore", 10)
		var hub = chunk.get_piece_at_hex(Hex.new(0, 0))
		hub.get_node("Hub").add_received(3)
		assert_string_contains(PieceStatus.describe(hub), "目標: Iron Ore 3/10")

	func test_ハブは名前を持つ():
		chunk.place_hub("iron_ore", 10)
		assert_eq(chunk.get_piece_at_hex(Hex.new(0, 0)).piece_name, "Hub")

	func test_つながっていないSenderは接続先がないと表示する():
		var sender = _place(SENDER, Hex.new(5, -2))
		assert_string_contains(PieceStatus.describe(sender), "接続先の Receiver がない")


class TestChestDescription:
	extends "res://tests/unit/utils/test_piece_status.gd"

	const CHEST_IN = preload("res://scenes/components/piece/chest_in.tscn")
	const CHEST_OUT = preload("res://scenes/components/piece/chest_out.tscn")

	func test_搬入チェストは共有倉庫の中身を表示する():
		var chest = _place(CHEST_IN, Hex.new(0, 0))
		chunk.storage.add("iron_ore", 12)
		assert_string_contains(PieceStatus.describe(chest), "倉庫: Iron Ore 12")

	func test_空の共有倉庫は空と表示する():
		var chest = _place(CHEST_IN, Hex.new(0, 0))
		assert_string_contains(PieceStatus.describe(chest), "倉庫: 空")

	func test_上限に達したアイテムは満杯と表示する():
		var chest = _place(CHEST_IN, Hex.new(0, 0))
		chunk.storage.add("iron_ore", SharedStorage.CAPACITY_PER_ITEM)
		assert_string_contains(PieceStatus.describe(chest), "Iron Ore 100（満杯）")

	func test_アイテムを選んでいない搬出チェストは選び方を表示する():
		var chest = _place(CHEST_OUT, Hex.new(0, 0))
		assert_string_contains(PieceStatus.describe(chest), "取り出すアイテム: 未選択（クリックして選ぶ）")

	func test_搬出チェストは選んだアイテムと倉庫の残りを表示する():
		var chest = _place(CHEST_OUT, Hex.new(0, 0))
		chunk.storage.add("coal", 7)
		chest.get_node("ChestOutput").select_item("coal")
		assert_string_contains(PieceStatus.describe(chest), "取り出すアイテム: Coal（倉庫に 7）")

	func test_搬出先の無い搬出チェストはその旨を表示する():
		var chest = _place(CHEST_OUT, Hex.new(0, 0))
		assert_string_contains(PieceStatus.describe(chest), "搬出先がない")
