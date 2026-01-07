class_name PieceShapes
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

# PieceDefinition構造体
class PieceDefinition:
	var shape: Array[Hex]
	var color: Color
	var input_ports: Array = []  # Array of Dictionary { "hex": Hex, "direction": int }
	var output_ports: Array = [] # Array of Dictionary { "hex": Hex, "direction": int }
	
	func _init(hex_shape: Array[Hex], hex_color: Color, inputs: Array = [], outputs: Array = []):
		shape = hex_shape
		color = hex_color
		input_ports = inputs
		output_ports = outputs

# PieceData - 形状データ定義
class PieceData:
	# 形状を構成する全ヘックスの、他のヘックスに接していない「外周」全てのポートを生成する
	static func _generate_all_external_ports(shape: Array[Hex]) -> Array:
		var ports = []
		var shape_set = {} # 高速なルックアップ用
		for h in shape:
			shape_set[h] = true
			
		for h in shape:
			for dir in range(6):
				var neighbor = Hex.neighbor(h, dir)
				if not shape_set.has(neighbor):
					ports.append({"hex": h, "direction": dir})
		return ports
	
	static var definitions = {
		PieceType.BAR: PieceDefinition.new(
			[Hex.new(-1, 0, 1), Hex.new(0, 0, 0), Hex.new(1, 0, -1), Hex.new(2, 0, -2)],
			Color("#D49A69"),
			[{"hex": Hex.new(-1, 0, 1), "direction": 3}], # Input at tail
			[{"hex": Hex.new(2, 0, -2), "direction": 0}]  # Output at head
		),
		PieceType.WORM: PieceDefinition.new(
			[Hex.new(-2, 0, 2), Hex.new(-1, 0, 1), Hex.new(0, 0, 0), Hex.new(0, 1, -1)],
			Color("#6AD38D"),
			_generate_all_external_ports([Hex.new(-2, 0, 2), Hex.new(-1, 0, 1), Hex.new(0, 0, 0), Hex.new(0, 1, -1)]),
			_generate_all_external_ports([Hex.new(-2, 0, 2), Hex.new(-1, 0, 1), Hex.new(0, 0, 0), Hex.new(0, 1, -1)])
		),
		PieceType.PISTOL: PieceDefinition.new(
			[Hex.new(1, -1, 0), Hex.new(0, -1, 1), Hex.new(0, 0, 0), Hex.new(0, 1, -1)],
			Color("#C2E479"),
			_generate_all_external_ports([Hex.new(1, -1, 0), Hex.new(0, -1, 1), Hex.new(0, 0, 0), Hex.new(0, 1, -1)]),
			_generate_all_external_ports([Hex.new(1, -1, 0), Hex.new(0, -1, 1), Hex.new(0, 0, 0), Hex.new(0, 1, -1)])
		),
		PieceType.PROPELLER: PieceDefinition.new(
			[Hex.new(0, 0, 0), Hex.new(-1, 0, 1), Hex.new(0, 1, -1), Hex.new(1, -1, 0)],
			Color("#8184F0"),
			_generate_all_external_ports([Hex.new(0, 0, 0), Hex.new(-1, 0, 1), Hex.new(0, 1, -1), Hex.new(1, -1, 0)]),
			_generate_all_external_ports([Hex.new(0, 0, 0), Hex.new(-1, 0, 1), Hex.new(0, 1, -1), Hex.new(1, -1, 0)])
		),
		PieceType.ARCH: PieceDefinition.new(
			[Hex.new(0, -1, 1), Hex.new(1, -1, 0), Hex.new(1, 0, -1), Hex.new(0, 1, -1)],
			Color("#F081AA"),
			_generate_all_external_ports([Hex.new(0, -1, 1), Hex.new(1, -1, 0), Hex.new(1, 0, -1), Hex.new(0, 1, -1)]),
			_generate_all_external_ports([Hex.new(0, -1, 1), Hex.new(1, -1, 0), Hex.new(1, 0, -1), Hex.new(0, 1, -1)])
		),
		PieceType.BEE: PieceDefinition.new(
			[Hex.new(0, 0, 0), Hex.new(0, 1, -1), Hex.new(1, 0, -1), Hex.new(1, 1, -2)],
			Color("#F3D283"),
			_generate_all_external_ports([Hex.new(0, 0, 0), Hex.new(0, 1, -1), Hex.new(1, 0, -1), Hex.new(1, 1, -2)]),
			_generate_all_external_ports([Hex.new(0, 0, 0), Hex.new(0, 1, -1), Hex.new(1, 0, -1), Hex.new(1, 1, -2)])
		),
		PieceType.WAVE: PieceDefinition.new(
			[Hex.new(-1, 0, 1), Hex.new(0, 0, 0), Hex.new(0, 1, -1), Hex.new(1, 1, -2)],
			Color("#85F7F2"),
			_generate_all_external_ports([Hex.new(-1, 0, 1), Hex.new(0, 0, 0), Hex.new(0, 1, -1), Hex.new(1, 1, -2)]),
			_generate_all_external_ports([Hex.new(-1, 0, 1), Hex.new(0, 0, 0), Hex.new(0, 1, -1), Hex.new(1, 1, -2)])
		),
		PieceType.CHEST: PieceDefinition.new(
			[Hex.new(0, 0, 0)],
			Color("#999999"), # グレー系の色
			_generate_all_external_ports([Hex.new(0, 0, 0)]),
			_generate_all_external_ports([Hex.new(0, 0, 0)])
		),
		# --- Test-only definitions ---
		PieceType.TEST_OUT: PieceDefinition.new(
			[Hex.new(0,0,0)], Color.WHITE, [], [{"hex": Hex.new(0,0,0), "direction": 0}]
		),
		PieceType.TEST_IN: PieceDefinition.new(
			[Hex.new(0,0,0)], Color.WHITE, [{"hex": Hex.new(0,0,0), "direction": 3}], []
		),
		PieceType.TEST_OUT_WRONG_DIR: PieceDefinition.new(
			[Hex.new(0,0,0)], Color.WHITE, [], [{"hex": Hex.new(0,0,0), "direction": 1}]
		),
	}
