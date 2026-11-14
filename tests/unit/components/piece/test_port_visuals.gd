extends GutTest

## 施設の出入口の描画。施設のマスの中からマスの辺まで短いベルトを描き、
## 隣のコンベアと途切れずつながって見えるようにする。

const CONVEYOR = preload("res://scenes/components/piece/conveyor.tscn")
const SMELTER = preload("res://scenes/components/piece/smelter_t1.tscn")
const MINER = preload("res://scenes/components/piece/miner_t1.tscn")
const SENDER = preload("res://scenes/components/piece/sender.tscn")
const CHEST_IN = preload("res://scenes/components/piece/chest_in.tscn")

var chunk: Chunk


func before_each():
	chunk = Chunk.new()
	add_child_autofree(chunk)


func _place(scene: PackedScene, hex: Hex, rotation: int = 0) -> Piece:
	chunk.place_piece(scene, hex, rotation)
	return chunk.get_piece_at_hex(hex)


func _ports_of(piece: Piece) -> PortVisuals:
	return piece.get_node_or_null("PortVisuals")


# 機械の出力ポートの先のマス
func _output_target_hex(machine: Piece) -> Hex:
	var port = machine.get_output_ports()[0]
	return Hex.neighbor(Hex.add(chunk.get_base_hex(machine), port["hex"]), port["direction"])


class TestGeometry:
	extends "res://tests/unit/components/piece/test_port_visuals.gd"

	func test_口のベルトはマスの中から始まり辺の中点まで伸びる():
		var layout = Layout.make_default()
		var segment = PortVisuals.stub_segment(Hex.new(0, 0), 0)
		var edge_mid = Layout.hex_to_pixel(layout, Hex.hex_directions[0]) * 0.5
		assert_lt(segment[0].length(), edge_mid.length(), "内側の端はマスの中")
		assert_gt(segment[0].length(), 0.0, "マスの中心からは始めない（施設の色を残す）")
		assert_almost_eq(segment[1].distance_to(edge_mid), PortVisuals.OVERLAP, 0.01)

	func test_口のベルトは隣のマスへ少しだけはみ出して_すき間を作らない():
		var layout = Layout.make_default()
		var segment = PortVisuals.stub_segment(Hex.new(0, 0), 0)
		var edge_mid = Layout.hex_to_pixel(layout, Hex.hex_directions[0]) * 0.5
		assert_gt(segment[1].length(), edge_mid.length())

	func test_口のベルトの幅はコンベアと同じ():
		assert_eq(PortVisuals.STUB_WIDTH, ConveyorVisuals.BELT_WIDTH)

	func test_複数マスの施設では口のあるマスを基準にする():
		var layout = Layout.make_default()
		var hex = Hex.new(1, 0)
		var segment = PortVisuals.stub_segment(hex, 3)
		var center = Layout.hex_to_pixel(layout, hex)
		assert_lt(segment[0].distance_to(center), segment[1].distance_to(center))


class TestOutputs:
	extends "res://tests/unit/components/piece/test_port_visuals.gd"

	func test_機械には出入口の描画が付く():
		assert_not_null(_ports_of(_place(SMELTER, Hex.new(0, 0))))

	func test_コンベアには付かない():
		assert_null(_ports_of(_place(CONVEYOR, Hex.new(0, 0))))

	func test_出力ポートの位置と向きに出口が描かれる():
		var smelter = _place(SMELTER, Hex.new(0, 0))
		var stubs = _ports_of(smelter).get_output_stubs()
		var port = smelter.get_output_ports()[0]
		assert_eq(stubs.size(), 1)
		assert_true(Hex.equals(stubs[0]["hex"], port["hex"]))
		assert_eq(stubs[0]["direction"], port["direction"])

	func test_回転すると出口の向きも変わる():
		var smelter = _place(SMELTER, Hex.new(0, 0))
		smelter.rotate_cw()
		var stubs = _ports_of(smelter).get_output_stubs()
		assert_eq(stubs[0]["direction"], smelter.get_output_ports()[0]["direction"])

	func test_Senderの出力はchunkの外へ向かうので出口を描かない():
		var sender = _place(SENDER, Hex.new(5, -2))
		assert_eq(_ports_of(sender).get_output_stubs(), [])

	func test_出力を持たない施設には出口が無い():
		assert_eq(_ports_of(_place(CHEST_IN, Hex.new(0, 0))).get_output_stubs(), [])

	func test_出入口は施設のタイルより手前に描かれる():
		var smelter = _place(SMELTER, Hex.new(0, 0))
		assert_gt(_ports_of(smelter).z_index, 10)

	func test_出入口を描く施設では従来の出力矢印を隠す():
		var smelter = _place(SMELTER, Hex.new(0, 0))
		assert_false(smelter._output_arrow.visible)


class TestInputs:
	extends "res://tests/unit/components/piece/test_port_visuals.gd"

	func test_何もつながっていない施設には入口が無い():
		assert_eq(_ports_of(_place(SMELTER, Hex.new(0, 0))).get_input_stubs(), [])

	func test_コンベアが流し込んでいる位置に入口が描かれる():
		var smelter = _place(SMELTER, Hex.new(0, 0))
		# (-2,0) から東向きのコンベア → Smelter の (-1,0) のマスへ流し込む
		_place(CONVEYOR, Hex.new(-2, 0))
		var stubs = _ports_of(smelter).get_input_stubs()
		assert_eq(stubs.size(), 1)
		assert_true(Hex.equals(stubs[0]["hex"], Hex.new(-1, 0)), "入口のマス（施設内の位置）")
		assert_eq(stubs[0]["direction"], 3, "コンベアのある西側の辺")

	func test_施設を向いていないコンベアでは入口が描かれない():
		var smelter = _place(SMELTER, Hex.new(0, 0))
		_place(CONVEYOR, Hex.new(-2, 0), 3)
		assert_eq(_ports_of(smelter).get_input_stubs(), [])

	func test_流し込んでいたコンベアを撤去すると入口が消える():
		var smelter = _place(SMELTER, Hex.new(0, 0))
		_place(CONVEYOR, Hex.new(-2, 0))
		chunk.remove_piece_at(Hex.new(-2, 0))
		assert_eq(_ports_of(smelter).get_input_stubs(), [])

	func test_機械の出力が隣の機械へ直接つながるときも入口が描かれる():
		chunk.mark_resource_hex(Hex.new(0, 0), "iron_ore")
		var miner = _place(MINER, Hex.new(0, 0))
		var target = _output_target_hex(miner)
		var chest = _place(CHEST_IN, target)
		var stubs = _ports_of(chest).get_input_stubs()
		assert_eq(stubs.size(), 1)
		assert_eq(stubs[0]["direction"], (miner.get_output_ports()[0]["direction"] + 3) % 6)

	func test_ハブにもコンベアが流し込む位置に入口が描かれる():
		chunk.place_hub("iron_ore", 10)
		_place(CONVEYOR, Hex.new(-1, 0))
		var hub = chunk.get_piece_at_hex(Hex.new(0, 0))
		assert_eq(_ports_of(hub).get_input_stubs().size(), 1)

	func test_2方向から流し込まれると入口が2つ描かれる():
		chunk.place_hub("iron_ore", 10)
		_place(CONVEYOR, Hex.new(-1, 0))
		_place(CONVEYOR, Hex.new(1, 0), 3)
		var hub = chunk.get_piece_at_hex(Hex.new(0, 0))
		assert_eq(_ports_of(hub).get_input_stubs().size(), 2)
