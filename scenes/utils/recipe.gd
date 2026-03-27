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


class RecipeDB:
	static var _recipes = {}
	static var _recipes_by_type: Dictionary = {}

	static func _static_init():
		if _recipes.is_empty():
			_register_defaults()

	static func _register_defaults():
		# Miner: Iron Ore (1.0s)
		register_recipe(Recipe.new("iron_ore", {}, {"iron_ore": 1}, 1.0), PieceData.Type.MINER)

		# Smelter: Iron Ingot (2.0s)
		register_recipe(
			Recipe.new("iron_ingot", {"iron_ore": 1}, {"iron_ingot": 1}, 2.0),
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

	static func get_recipes_by_type(piece_type: PieceData.Type) -> Array[Recipe]:
		_static_init()
		var result: Array[Recipe] = []
		for r in _recipes_by_type.get(piece_type, []):
			result.append(r)
		return result
