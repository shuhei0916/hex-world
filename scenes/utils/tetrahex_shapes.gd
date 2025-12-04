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
	WAVE
}

# TetrahexDefinition構造体
class TetrahexDefinition:
	var shape: Array[Hex]
	var color: Color
	
	func _init(hex_shape: Array[Hex], hex_color: Color):
		shape = hex_shape
		color = hex_color

# TetrahexData - 形状データ定義
class TetrahexData:
	static var definitions = {
		TetrahexType.BAR: TetrahexDefinition.new(
			[Hex.new(-1, 0, 1), Hex.new(0, 0, 0), Hex.new(1, 0, -1), Hex.new(2, 0, -2)],
			Color("#D49A69")
		),
		TetrahexType.WORM: TetrahexDefinition.new(
			[Hex.new(-2, 0, 2), Hex.new(-1, 0, 1), Hex.new(0, 0, 0), Hex.new(0, 1, -1)],
			Color("#6AD38D")
		),
		TetrahexType.PISTOL: TetrahexDefinition.new(
			[Hex.new(1, -1, 0), Hex.new(0, -1, 1), Hex.new(0, 0, 0), Hex.new(0, 1, -1)],
			Color("#C2E479")
		),
		TetrahexType.PROPELLER: TetrahexDefinition.new(
			[Hex.new(0, 0, 0), Hex.new(-1, 0, 1), Hex.new(0, 1, -1), Hex.new(1, -1, 0)],
			Color("#8184F0")
		),
		TetrahexType.ARCH: TetrahexDefinition.new(
			[Hex.new(0, -1, 1), Hex.new(1, -1, 0), Hex.new(1, 0, -1), Hex.new(0, 1, -1)],
			Color("#F081AA")
		),
		TetrahexType.BEE: TetrahexDefinition.new(
			[Hex.new(0, 0, 0), Hex.new(0, 1, -1), Hex.new(1, 0, -1), Hex.new(1, 1, -2)],
			Color("#F3D283")
		),
		TetrahexType.WAVE: TetrahexDefinition.new(
			[Hex.new(-1, 0, 1), Hex.new(0, 0, 0), Hex.new(0, 1, -1), Hex.new(1, 1, -2)],
			Color("#85F7F2")
		)
	}
