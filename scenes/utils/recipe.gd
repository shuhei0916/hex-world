class_name Recipe
extends RefCounted

var id: String
var inputs: Dictionary
var outputs: Dictionary
var craft_time: float


func _init(
	id_val: String,
	inputs_val: Dictionary,
	outputs_val: Dictionary,
	craft_time_val: float,
):
	id = id_val
	inputs = inputs_val
	outputs = outputs_val
	craft_time = craft_time_val


# 基準生産速度（個/分）。output_multiplier は加味しない（配置場所に依存しない base speed）。
func items_per_minute() -> float:
	if craft_time <= 0.0:
		return 0.0
	return 60.0 / craft_time


class RecipeDB:
	static var _recipes = {}
	static var _recipes_by_type: Dictionary = {}

	static func _static_init():
		if _recipes.is_empty():
			_register_defaults()

	static func _register_defaults():
		# Miner: 足元の鉱床の資源を採掘する (1.0s)。先頭の iron_ore が配置直後の既定レシピ
		for resource_type in ["iron_ore", "copper_ore", "coal"]:
			register_recipe(
				Recipe.new(resource_type, {}, {resource_type: 1}, 1.0), PieceData.Type.MINER
			)

		# Smelter: Iron Ingot (2.0s)
		register_recipe(
			Recipe.new("iron_ingot", {"iron_ore": 1}, {"iron_ingot": 1}, 2.0),
			PieceData.Type.SMELTER
		)

		# Smelter: Copper Ingot (2.0s) — 山岳バイオームの銅鉱石から
		register_recipe(
			Recipe.new("copper_ingot", {"copper_ore": 1}, {"copper_ingot": 1}, 2.0),
			PieceData.Type.SMELTER
		)

		# Assembler: Iron Plate (3.0s)
		register_recipe(
			Recipe.new("iron_plate", {"iron_ingot": 1}, {"iron_plate": 1}, 3.0),
			PieceData.Type.ASSEMBLER
		)

		# Cutter: Iron Rod (4.0s)
		register_recipe(
			Recipe.new("iron_rod", {"iron_ingot": 1}, {"iron_rod": 1}, 4.0), PieceData.Type.CUTTER
		)

		# Mixer: Screw (6.0s)
		register_recipe(
			Recipe.new("screw", {"iron_rod": 1}, {"screw": 1}, 6.0), PieceData.Type.MIXER
		)

		# Mixer: Steel (4.0s) — 森林バイオームの石炭と鉄インゴットから
		register_recipe(
			Recipe.new("steel", {"iron_ingot": 1, "coal": 1}, {"steel": 1}, 4.0),
			PieceData.Type.MIXER
		)

		# Cutter: Copper Wire (3.0s) — 銅インゴットから
		register_recipe(
			Recipe.new("copper_wire", {"copper_ingot": 1}, {"copper_wire": 1}, 3.0),
			PieceData.Type.CUTTER
		)

		# Assembler: Steel Beam (4.0s) — 鋼材から
		register_recipe(
			Recipe.new("steel_beam", {"steel": 1}, {"steel_beam": 1}, 4.0), PieceData.Type.ASSEMBLER
		)

		# Mixer: Circuit (6.0s) — 銅線と鉄板から（山岳と平原の両方の資源が要る）
		register_recipe(
			Recipe.new("circuit", {"copper_wire": 1, "iron_plate": 1}, {"circuit": 1}, 6.0),
			PieceData.Type.MIXER
		)

	static func register_recipe(
		recipe: Recipe, piece_type: PieceData.Type = PieceData.Type.CONVEYOR
	):
		_recipes[recipe.id] = recipe
		if not _recipes_by_type.has(piece_type):
			_recipes_by_type[piece_type] = []
		_recipes_by_type[piece_type].append(recipe)

	static func get_recipe(id: String) -> Recipe:
		_static_init()
		return _recipes.get(id)

	# 指定した資源を採掘する Miner のレシピ。採掘できない資源なら null。
	static func get_mining_recipe(resource_type: String) -> Recipe:
		for recipe in get_recipes_by_type(PieceData.Type.MINER):
			if recipe.outputs.has(resource_type):
				return recipe
		return null

	static func get_recipes_by_type(piece_type: PieceData.Type) -> Array[Recipe]:
		_static_init()
		var result: Array[Recipe] = []
		for r in _recipes_by_type.get(piece_type, []):
			result.append(r)
		return result
