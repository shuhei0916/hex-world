class_name PieceData
extends RefCounted

enum Type {
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
	"hoge": Color("#D49A69"),
	"foo": Color("#C2E479"),
	"bar": Color("#8184F0"),
	"hoho": Color("#F081AA"),
	"": Color("#D49A69")
}

# gdlint:disable=class-variable-name
static var DATA: Dictionary:
	get:
		if _data_map.is_empty():
			_initialize_data()
		return _data_map

# gdlint:disable=class-variable-name
static var _data_map = {}

# インスタンス変数
var shape: Array[Hex]
var color: Color
var output_ports: Array = []
var role: String = ""


func _init(hex_shape: Array[Hex], outputs: Array = [], role_val: String = ""):
	shape = hex_shape
	role = role_val
	color = FACILITY_COLORS.get(role, FACILITY_COLORS[""])

	output_ports = []
	for out in outputs:
		var port = out.duplicate()
		if port.has("direction") and port["direction"] is String:
			var dir_str = port["direction"]
			if Hex.DIR_NAME_TO_INDEX.has(dir_str):
				port["direction"] = Hex.DIR_NAME_TO_INDEX[dir_str]
		output_ports.append(port)


static func get_data(type: Type) -> PieceData:
	if _data_map.is_empty():
		_initialize_data()
	return _data_map.get(type)


static func _initialize_data():
	_data_map = {
		Type.BAR:
		new(
			[Hex.new(-1, 0, 1), Hex.new(0, 0, 0), Hex.new(1, 0, -1), Hex.new(2, 0, -2)],
			[{"hex": Hex.new(2, 0, -2), "direction": "E"}],
			"hoge"
		),
		Type.WORM:
		new(
			[Hex.new(-2, 0, 2), Hex.new(-1, 0, 1), Hex.new(0, 0, 0), Hex.new(0, 1, -1)],
			[{"hex": Hex.new(0, 0, 0), "direction": "E"}],
			"smelter"
		),
		Type.PISTOL:
		new(
			[Hex.new(1, -1, 0), Hex.new(0, -1, 1), Hex.new(0, 0, 0), Hex.new(0, 1, -1)],
			[{"hex": Hex.new(1, -1, 0), "direction": "NE"}],
			"foo"
		),
		Type.PROPELLER:
		new(
			[Hex.new(0, 0, 0), Hex.new(-1, 0, 1), Hex.new(0, 1, -1), Hex.new(1, -1, 0)],
			[{"hex": Hex.new(0, 0, 0), "direction": "E"}],
			"bar"
		),
		Type.ARCH:
		new(
			[Hex.new(0, -1, 1), Hex.new(1, -1, 0), Hex.new(1, 0, -1), Hex.new(0, 1, -1)],
			[{"hex": Hex.new(0, -1, 1), "direction": "NW"}],
			"hoho"
		),
		Type.BEE:
		new(
			[Hex.new(0, 0, 0), Hex.new(0, 1, -1), Hex.new(1, 0, -1), Hex.new(1, 1, -2)],
			[{"hex": Hex.new(0, 1, -1), "direction": "SW"}],
			"miner"
		),
		Type.WAVE:
		new(
			[Hex.new(-1, 0, 1), Hex.new(0, 0, 0), Hex.new(0, 1, -1), Hex.new(1, 1, -2)],
			[{"hex": Hex.new(0, 0, 0), "direction": "NW"}],
			"constructor"
		),
		Type.CHEST: new([Hex.new(0, 0, 0)], [], "storage"),
	}


# インスタンスメソッド
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
