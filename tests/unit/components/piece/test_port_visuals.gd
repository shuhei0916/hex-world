extends GutTest

## 施設の出口の向きの印。施設の縁に小さな三角を描き、どの辺から排出するかを示す。

const CONVEYOR = preload("res://scenes/components/piece/conveyor.tscn")
const SMELTER = preload("res://scenes/components/piece/smelter_t1.tscn")
const MINER = preload("res://scenes/components/piece/miner_t1.tscn")
const BRIDGE = preload("res://scenes/components/piece/bridge.tscn")
const CHEST_IN = preload("res://scenes/components/piece/chest_in.tscn")

var chunk: Chunk


func before_each():
	chunk = Chunk.new()
	add_child_autofree(chunk)


func _place(scene: PackedScene, hex: Vector2i, rotation: int = 0) -> Piece:
	chunk.place_piece(scene, hex, rotation)
	return chunk.get_piece_at_hex(hex)


func _ports_of(piece: Piece) -> PortVisuals:
	return piece.get_node_or_null("PortVisuals")


# 機械の出力ポートの先のマス
func _output_target_hex(machine: Piece) -> Vector2i:
	var port = machine.get_output_ports()[0]
	return Hex.neighbor(chunk.get_base_hex(machine) + port["hex"], port["direction"])


class TestOutputs:
	extends "res://tests/unit/components/piece/test_port_visuals.gd"

	func test_機械には出口の印が付く():
		assert_not_null(_ports_of(_place(SMELTER, Vector2i(0, 0))))

	func test_コンベアには付かない():
		assert_null(_ports_of(_place(CONVEYOR, Vector2i(0, 0))))

	func test_出力ポートの位置と向きに出口の印が描かれる():
		var smelter = _place(SMELTER, Vector2i(0, 0))
		var stubs = _ports_of(smelter).get_output_stubs()
		var port = smelter.get_output_ports()[0]
		assert_eq(stubs.size(), 1)
		assert_true(stubs[0]["hex"] == port["hex"])
		assert_eq(stubs[0]["direction"], port["direction"])

	func test_回転すると出口の向きも変わる():
		var smelter = _place(SMELTER, Vector2i(0, 0))
		smelter.set_rotation_state((smelter.rotation_state + 1) % 6)
		var stubs = _ports_of(smelter).get_output_stubs()
		assert_eq(stubs[0]["direction"], smelter.get_output_ports()[0]["direction"])

	func test_橋の出力はchunkの外へ向かうので出口の印を描かない():
		var bridge = _place(BRIDGE, Vector2i(5, -2))
		assert_eq(_ports_of(bridge).get_output_stubs(), [])

	func test_出力を持たない施設には出口が無い():
		assert_eq(_ports_of(_place(CHEST_IN, Vector2i(0, 0))).get_output_stubs(), [])

	func test_出口の印は施設のタイルより手前に描かれる():
		var smelter = _place(SMELTER, Vector2i(0, 0))
		assert_gt(_ports_of(smelter).z_index, PortVisuals.PIECE_TILE_Z)

	func test_出口の印は施設のタイルの縁の内側に置く():
		var position = PortVisuals.marker_position(Vector2i(0, 0), 0)
		assert_lt(position.length() + PortVisuals.MARKER_SIZE, PortVisuals.TILE_INRADIUS)
		assert_gt(position.length(), PortVisuals.TILE_INRADIUS * 0.5, "中心ではなく縁の近く")

	func test_出口は印で示し矢印の画像は作らない():
		var smelter = _place(SMELTER, Vector2i(0, 0))
		var arrows = smelter.get_children().filter(
			func(c): return c is Sprite2D and c.texture == Piece.FORWARD_TEXTURE
		)
		assert_eq(arrows, [])
