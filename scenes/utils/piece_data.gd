class_name PieceData
extends RefCounted

enum Type {
	CONVEYOR,
	SMELTER,
	CUTTER,
	MIXER,
	PAINTER,
	MINER,
	ASSEMBLER,
	CHEST,
}

const FACILITY_COLORS = {
	"miner": Color("#F3D283"),
	"smelter": Color("#6AD38D"),
	"assembler": Color("#85F7F2"),
	"storage": Color("#999999"),
	"conveyor": Color("#D49A69"),
	"cutter": Color("#C2E479"),
	"mixer": Color("#8184F0"),
	"painter": Color("#F081AA"),
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
static var _miner_scene: PackedScene
static var _smelter_scene: PackedScene
static var _assembler_scene: PackedScene

# インスタンス変数
var shape: Array[Hex]
var color: Color
var output_ports: Array = []
var role: String = ""
var scene: PackedScene = null
var piece_type: int = -1


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


static func _make(
	hex_shape: Array[Hex],
	outputs: Array,
	role_val: String,
	scene_val: PackedScene = null,
	type_val: int = -1
) -> PieceData:
	var d = PieceData.new(hex_shape, outputs, role_val)
	d.scene = scene_val
	d.piece_type = type_val
	return d


static func _initialize_data():
	_miner_scene = load("res://scenes/components/piece/miner.tscn")
	_smelter_scene = load("res://scenes/components/piece/smelter.tscn")
	_assembler_scene = load("res://scenes/components/piece/assembler.tscn")
	_data_map = {
		Type.CONVEYOR:
		_make(
			[Hex.new(-1, 0, 1), Hex.new(0, 0, 0), Hex.new(1, 0, -1), Hex.new(2, 0, -2)],
			[{"hex": Hex.new(2, 0, -2), "direction": "E"}],
			"conveyor",
			null,
			Type.CONVEYOR
		),
		Type.SMELTER:
		_make(
			[Hex.new(-2, 0, 2), Hex.new(-1, 0, 1), Hex.new(0, 0, 0), Hex.new(0, 1, -1)],
			[{"hex": Hex.new(0, 0, 0), "direction": "E"}],
			"smelter",
			_smelter_scene,
			Type.SMELTER
		),
		Type.CUTTER:
		_make(
			[Hex.new(1, -1, 0), Hex.new(0, -1, 1), Hex.new(0, 0, 0), Hex.new(0, 1, -1)],
			[{"hex": Hex.new(1, -1, 0), "direction": "NE"}],
			"cutter",
			null,
			Type.CUTTER
		),
		Type.MIXER:
		_make(
			[Hex.new(0, 0, 0), Hex.new(-1, 0, 1), Hex.new(0, 1, -1), Hex.new(1, -1, 0)],
			[{"hex": Hex.new(0, 0, 0), "direction": "E"}],
			"mixer",
			null,
			Type.MIXER
		),
		Type.PAINTER:
		_make(
			[Hex.new(0, -1, 1), Hex.new(1, -1, 0), Hex.new(1, 0, -1), Hex.new(0, 1, -1)],
			[{"hex": Hex.new(0, -1, 1), "direction": "NW"}],
			"painter",
			null,
			Type.PAINTER
		),
		Type.MINER:
		_make(
			[Hex.new(0, 0, 0), Hex.new(0, 1, -1), Hex.new(1, 0, -1), Hex.new(1, 1, -2)],
			[{"hex": Hex.new(0, 1, -1), "direction": "SW"}],
			"miner",
			_miner_scene,
			Type.MINER
		),
		Type.ASSEMBLER:
		_make(
			[Hex.new(-1, 0, 1), Hex.new(0, 0, 0), Hex.new(0, 1, -1), Hex.new(1, 1, -2)],
			[{"hex": Hex.new(0, 0, 0), "direction": "NW"}],
			"assembler",
			_assembler_scene,
			Type.ASSEMBLER
		),
		Type.CHEST: _make([Hex.new(0, 0, 0)], [], "storage", null, Type.CHEST),
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
