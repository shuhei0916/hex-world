class_name Recipe
extends RefCounted

var id: String
var inputs: Dictionary
var outputs: Dictionary
var craft_time: float
var role: String


func _init(
	id_val: String,
	inputs_val: Dictionary,
	outputs_val: Dictionary,
	craft_time_val: float,
	role_val: String = ""
):
	id = id_val
	inputs = inputs_val
	outputs = outputs_val
	craft_time = craft_time_val
	role = role_val


class RecipeDB:
	static var _recipes = {}

	static func _static_init():
		if _recipes.is_empty():
			_register_defaults()

	static func _register_defaults():
		# Miner: Iron Ore (1.0s)
		register_recipe(Recipe.new("iron_ore", {}, {"iron_ore": 1}, 1.0, "miner"))

		# Smelter: Iron Ingot (2.0s)
		register_recipe(
			Recipe.new("iron_ingot", {"iron_ore": 1}, {"iron_ingot": 1}, 2.0, "smelter")
		)

		# Constructor: Iron Plate (3.0s)
		register_recipe(
			Recipe.new("iron_plate", {"iron_ingot": 1}, {"iron_plate": 1}, 3.0, "constructor")
		)

	static func register_recipe(recipe: Recipe):
		_recipes[recipe.id] = recipe

	static func get_recipe(id: String) -> Recipe:
		_static_init()
		return _recipes.get(id)

	static func get_recipes_by_role(role: String) -> Array[Recipe]:
		_static_init()
		var result: Array[Recipe] = []
		for recipe in _recipes.values():
			if recipe.role == role:
				result.append(recipe)
		return result
