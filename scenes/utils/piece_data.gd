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

const FACILITY_COLORS_BY_TYPE = {
	0: Color("#D49A69"),  # CONVEYOR
	1: Color("#6AD38D"),  # SMELTER
	2: Color("#C2E479"),  # CUTTER
	3: Color("#8184F0"),  # MIXER
	4: Color("#F081AA"),  # PAINTER
	5: Color("#F3D283"),  # MINER
	6: Color("#85F7F2"),  # ASSEMBLER
	7: Color("#999999"),  # CHEST
}
