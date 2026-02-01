class_name PieceDB
extends RefCounted

# PieceType enum定義
enum PieceType {
	BAR,
	WORM,
	PISTOL,
	PROPELLER,
	ARCH,
	BEE,
	WAVE,
	CHEST,
	# --- Test-only types ---
	TEST_OUT,
	TEST_IN,
	TEST_OUT_WRONG_DIR
}


class PieceData:
	var shape: Array[Hex]

	var color: Color

	var output_ports: Array = []  # Array of Dictionary { "hex": Hex, "direction": int }

	var facility_type: String = ""

	func _init(
		hex_shape: Array[Hex], hex_color: Color, outputs: Array = [], facility_type_val: String = ""
	):
		shape = hex_shape

		color = hex_color

		output_ports = outputs

		facility_type = facility_type_val


# gdlint:disable=class-variable-name
static var DATA = {
	PieceType.BAR:
	PieceData.new(
		[Hex.new(-1, 0, 1), Hex.new(0, 0, 0), Hex.new(1, 0, -1), Hex.new(2, 0, -2)],
		Color("#D49A69"),
		[{"hex": Hex.new(2, 0, -2), "direction": 0}],  # Output at head
		"miner"
	),
	PieceType.WORM:
	PieceData.new(
		[Hex.new(-2, 0, 2), Hex.new(-1, 0, 1), Hex.new(0, 0, 0), Hex.new(0, 1, -1)],
		Color("#6AD38D"),
		[{"hex": Hex.new(0, 0, 0), "direction": 0}],  # Output
		"smelter"
	),
	PieceType.PISTOL:
	PieceData.new(
		[Hex.new(1, -1, 0), Hex.new(0, -1, 1), Hex.new(0, 0, 0), Hex.new(0, 1, -1)],
		Color("#C2E479"),
		_generate_all_external_ports(
			[Hex.new(1, -1, 0), Hex.new(0, -1, 1), Hex.new(0, 0, 0), Hex.new(0, 1, -1)]
		)
	),
	PieceType.PROPELLER:
	PieceData.new(
		[Hex.new(0, 0, 0), Hex.new(-1, 0, 1), Hex.new(0, 1, -1), Hex.new(1, -1, 0)],
		Color("#8184F0"),
		[{"hex": Hex.new(0, 0, 0), "direction": 0}],  # Output
		"constructor"
	),
	PieceType.ARCH:
	PieceData.new(
		[Hex.new(0, -1, 1), Hex.new(1, -1, 0), Hex.new(1, 0, -1), Hex.new(0, 1, -1)],
		Color("#F081AA"),
		_generate_all_external_ports(
			[Hex.new(0, -1, 1), Hex.new(1, -1, 0), Hex.new(1, 0, -1), Hex.new(0, 1, -1)]
		)
	),
	PieceType.BEE:
	PieceData.new(
		[Hex.new(0, 0, 0), Hex.new(0, 1, -1), Hex.new(1, 0, -1), Hex.new(1, 1, -2)],
		Color("#F3D283"),
		_generate_all_external_ports(
			[Hex.new(0, 0, 0), Hex.new(0, 1, -1), Hex.new(1, 0, -1), Hex.new(1, 1, -2)]
		)
	),
	PieceType.WAVE:
	PieceData.new(
		[Hex.new(-1, 0, 1), Hex.new(0, 0, 0), Hex.new(0, 1, -1), Hex.new(1, 1, -2)],
		Color("#85F7F2"),
		_generate_all_external_ports(
			[Hex.new(-1, 0, 1), Hex.new(0, 0, 0), Hex.new(0, 1, -1), Hex.new(1, 1, -2)]
		)
	),
	PieceType.CHEST:
	PieceData.new(
		[Hex.new(0, 0, 0)],
		Color("#999999"),
		_generate_all_external_ports([Hex.new(0, 0, 0)]),  # グレー系の色
		"storage"
	),
	# --- Test-only definitions ---
	PieceType.TEST_OUT:
	PieceData.new([Hex.new(0, 0, 0)], Color.WHITE, [{"hex": Hex.new(0, 0, 0), "direction": 0}]),
	PieceType.TEST_IN: PieceData.new([Hex.new(0, 0, 0)], Color.WHITE, []),
	PieceType.TEST_OUT_WRONG_DIR:
	PieceData.new([Hex.new(0, 0, 0)], Color.WHITE, [{"hex": Hex.new(0, 0, 0), "direction": 1}]),
}


static func get_data(type: int) -> PieceData:
	return DATA.get(type)


# 形状を構成する全ヘックスの、他のヘックスに接していない「外周」全てのポートを生成する
static func _generate_all_external_ports(shape: Array[Hex]) -> Array:
	var ports = []
	var shape_set = {}  # 高速なルックアップ用
	for h in shape:
		shape_set[h] = true

	for h in shape:
		for dir in range(6):
			var neighbor = Hex.neighbor(h, dir)
			if not shape_set.has(neighbor):
				ports.append({"hex": h, "direction": dir})
	return ports
