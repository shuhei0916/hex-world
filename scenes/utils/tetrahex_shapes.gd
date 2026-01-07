class_name TetrahexShapes
extends RefCounted

# TetrahexType enum定義
enum TetrahexType {
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

# TetrahexDefinition構造体
class TetrahexDefinition:
	var shape: Array[Hex]
	var color: Color
	var input_ports: Array = []  # Array of Dictionary { "hex": Hex, "direction": int }
	var output_ports: Array = [] # Array of Dictionary { "hex": Hex, "direction": int }
	
	func _init(hex_shape: Array[Hex], hex_color: Color, inputs: Array = [], outputs: Array = []):
		shape = hex_shape
		color = hex_color
		input_ports = inputs
		output_ports = outputs

# TetrahexData - 形状データ定義
class TetrahexData:
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
		TetrahexType.BAR: TetrahexDefinition.new(
			[Hex.new(-1, 0, 1), Hex.new(0, 0, 0), Hex.new(1, 0, -1), Hex.new(2, 0, -2)],
			Color("#D49A69"),
			[{"hex": Hex.new(-1, 0, 1), "direction": 3}], # Input at tail
			[{"hex": Hex.new(2, 0, -2), "direction": 0}]  # Output at head
		),
		TetrahexType.WORM: TetrahexDefinition.new(
			[Hex.new(-2, 0, 2), Hex.new(-1, 0, 1), Hex.new(0, 0, 0), Hex.new(0, 1, -1)],
			Color("#6AD38D"),
			_generate_all_external_ports([Hex.new(-2, 0, 2), Hex.new(-1, 0, 1), Hex.new(0, 0, 0), Hex.new(0, 1, -1)]),
			_generate_all_external_ports([Hex.new(-2, 0, 2), Hex.new(-1, 0, 1), Hex.new(0, 0, 0), Hex.new(0, 1, -1)])
		),
		TetrahexType.PISTOL: TetrahexDefinition.new(
			[Hex.new(1, -1, 0), Hex.new(0, -1, 1), Hex.new(0, 0, 0), Hex.new(0, 1, -1)],
			Color("#C2E479"),
			_generate_all_external_ports([Hex.new(1, -1, 0), Hex.new(0, -1, 1), Hex.new(0, 0, 0), Hex.new(0, 1, -1)]),
			_generate_all_external_ports([Hex.new(1, -1, 0), Hex.new(0, -1, 1), Hex.new(0, 0, 0), Hex.new(0, 1, -1)])
		),
		TetrahexType.PROPELLER: TetrahexDefinition.new(
			[Hex.new(0, 0, 0), Hex.new(-1, 0, 1), Hex.new(0, 1, -1), Hex.new(1, -1, 0)],
			Color("#8184F0"),
			_generate_all_external_ports([Hex.new(0, 0, 0), Hex.new(-1, 0, 1), Hex.new(0, 1, -1), Hex.new(1, -1, 0)]),
			_generate_all_external_ports([Hex.new(0, 0, 0), Hex.new(-1, 0, 1), Hex.new(0, 1, -1), Hex.new(1, -1, 0)])
		),
		TetrahexType.ARCH: TetrahexDefinition.new(
			[Hex.new(0, -1, 1), Hex.new(1, -1, 0), Hex.new(1, 0, -1), Hex.new(0, 1, -1)],
			Color("#F081AA"),
			_generate_all_external_ports([Hex.new(0, -1, 1), Hex.new(1, -1, 0), Hex.new(1, 0, -1), Hex.new(0, 1, -1)]),
			_generate_all_external_ports([Hex.new(0, -1, 1), Hex.new(1, -1, 0), Hex.new(1, 0, -1), Hex.new(0, 1, -1)])
		),
		TetrahexType.BEE: TetrahexDefinition.new(
			[Hex.new(0, 0, 0), Hex.new(0, 1, -1), Hex.new(1, 0, -1), Hex.new(1, 1, -2)],
			Color("#F3D283"),
			_generate_all_external_ports([Hex.new(0, 0, 0), Hex.new(0, 1, -1), Hex.new(1, 0, -1), Hex.new(1, 1, -2)]),
			_generate_all_external_ports([Hex.new(0, 0, 0), Hex.new(0, 1, -1), Hex.new(1, 0, -1), Hex.new(1, 1, -2)])
		),
		TetrahexType.WAVE: TetrahexDefinition.new(
			[Hex.new(-1, 0, 1), Hex.new(0, 0, 0), Hex.new(0, 1, -1), Hex.new(1, 1, -2)],
			Color("#85F7F2"),
			_generate_all_external_ports([Hex.new(-1, 0, 1), Hex.new(0, 0, 0), Hex.new(0, 1, -1), Hex.new(1, 1, -2)]),
			_generate_all_external_ports([Hex.new(-1, 0, 1), Hex.new(0, 0, 0), Hex.new(0, 1, -1), Hex.new(1, 1, -2)])
		),
		TetrahexType.CHEST: TetrahexDefinition.new(
			[Hex.new(0, 0, 0)],
			Color("#999999"), # グレー系の色
			_generate_all_external_ports([Hex.new(0, 0, 0)]),
			_generate_all_external_ports([Hex.new(0, 0, 0)])
		),
		# --- Test-only definitions ---
		TetrahexType.TEST_OUT: TetrahexDefinition.new(
			[Hex.new(0,0,0)], Color.WHITE, [], [{"hex": Hex.new(0,0,0), "direction": 0}]
		),
		TetrahexType.TEST_IN: TetrahexDefinition.new(
			[Hex.new(0,0,0)], Color.WHITE, [{"hex": Hex.new(0,0,0), "direction": 3}], []
		),
		TetrahexType.TEST_OUT_WRONG_DIR: TetrahexDefinition.new(
			[Hex.new(0,0,0)], Color.WHITE, [], [{"hex": Hex.new(0,0,0), "direction": 1}]
		),
	}
