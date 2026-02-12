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
}

const FACILITY_COLORS = {
	"miner": Color("#F3D283"),
	"smelter": Color("#6AD38D"),
	"constructor": Color("#85F7F2"),
	"storage": Color("#999999"),
	"hoge": Color("#D49A69"),  # BAR color
	"foo": Color("#C2E479"),  # PISTOL color
	"bar": Color("#8184F0"),  # PROPELLER color
	"hoho": Color("#F081AA"),  # ARCH color
	"": Color("#D49A69")  # Default color
}


class PieceData:
	var shape: Array[Hex]

	var color: Color

	var output_ports: Array = []  # Array of Dictionary { "hex": Hex, "direction": int }

	var facility_type: String = ""

	func _init(hex_shape: Array[Hex], outputs: Array = [], facility_type_val: String = ""):
		shape = hex_shape

		facility_type = facility_type_val

		color = FACILITY_COLORS.get(facility_type, FACILITY_COLORS[""])

		# 方向指定が文字列の場合は数値に変換
		output_ports = []
		for out in outputs:
			var port = out.duplicate()
			if port.has("direction") and port["direction"] is String:
				var dir_str = port["direction"]
				if Hex.DIR_NAME_TO_INDEX.has(dir_str):
					port["direction"] = Hex.DIR_NAME_TO_INDEX[dir_str]
			output_ports.append(port)

	func get_rotated_shape(rotation_state: int) -> Array[Hex]:
		var rotated_shape: Array[Hex] = []
		for hex in shape:
			var rotated_hex = hex
			for i in range(rotation_state):
				rotated_hex = Hex.rotate_right(rotated_hex)
			rotated_shape.append(rotated_hex)
		return rotated_shape

	func get_rotated_ports(rotation_state: int) -> Array:
		var rotated_ports: Array = []
		for port_def in output_ports:
			var rotated_hex = port_def.hex
			for i in range(rotation_state):
				rotated_hex = Hex.rotate_right(rotated_hex)

			var rotated_direction = (port_def.direction - rotation_state + 6) % 6
			rotated_ports.append({"hex": rotated_hex, "direction": rotated_direction})

		return rotated_ports


# gdlint:disable=class-variable-name
static var DATA = {
	PieceType.BAR:
	PieceData.new(
		[Hex.new(-1, 0, 1), Hex.new(0, 0, 0), Hex.new(1, 0, -1), Hex.new(2, 0, -2)],
		[{"hex": Hex.new(2, 0, -2), "direction": "E"}],  # Output at head
		"hoge"
	),
	PieceType.WORM:
	PieceData.new(
		[Hex.new(-2, 0, 2), Hex.new(-1, 0, 1), Hex.new(0, 0, 0), Hex.new(0, 1, -1)],
		[{"hex": Hex.new(0, 0, 0), "direction": "E"}],  # Output
		"smelter"
	),
	PieceType.PISTOL:
	PieceData.new(
		[Hex.new(1, -1, 0), Hex.new(0, -1, 1), Hex.new(0, 0, 0), Hex.new(0, 1, -1)],
		[{"hex": Hex.new(1, -1, 0), "direction": "NE"}],
		"foo"
	),
	PieceType.PROPELLER:
	PieceData.new(
		[Hex.new(0, 0, 0), Hex.new(-1, 0, 1), Hex.new(0, 1, -1), Hex.new(1, -1, 0)],
		[{"hex": Hex.new(0, 0, 0), "direction": "E"}],
		"bar"
	),
	PieceType.ARCH:
	PieceData.new(
		[Hex.new(0, -1, 1), Hex.new(1, -1, 0), Hex.new(1, 0, -1), Hex.new(0, 1, -1)],
		[{"hex": Hex.new(0, -1, 1), "direction": "NW"}],
		"hoho"
	),
	PieceType.BEE:
	PieceData.new(
		[Hex.new(0, 0, 0), Hex.new(0, 1, -1), Hex.new(1, 0, -1), Hex.new(1, 1, -2)],
		[{"hex": Hex.new(0, 1, -1), "direction": "SW"}],
		"miner"
	),
	PieceType.WAVE:
	PieceData.new(
		[Hex.new(-1, 0, 1), Hex.new(0, 0, 0), Hex.new(0, 1, -1), Hex.new(1, 1, -2)],
		[{"hex": Hex.new(0, 0, 0), "direction": "NW"}],
		"constructor"
	),
	PieceType.CHEST: PieceData.new([Hex.new(0, 0, 0)], [], "storage"),
}


static func get_data(type: int) -> PieceData:
	return DATA.get(type)
