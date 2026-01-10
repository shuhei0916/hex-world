class_name Recipe
extends RefCounted

var id: String
var inputs: Dictionary
var outputs: Dictionary
var craft_time: float


func _init(id_val: String, inputs_val: Dictionary, outputs_val: Dictionary, craft_time_val: float):
	id = id_val
	inputs = inputs_val
	outputs = outputs_val
	craft_time = craft_time_val


class RecipeDB:
	static var _recipes = {}

	static func _static_init():
		if _recipes.is_empty():
			_register_defaults()

	static func _register_defaults():
		register_recipe(Recipe.new("smelt_iron_ingot", {"iron_ore": 1}, {"iron_ingot": 1}, 2.0))  # 2秒で精錬
		register_recipe(
			Recipe.new("assemble_iron_plate", {"iron_ingot": 1}, {"iron_plate": 1}, 3.0)  # 3秒で製作
		)

	static func register_recipe(recipe: Recipe):
		_recipes[recipe.id] = recipe

	static func get_recipe(id: String) -> Recipe:
		_static_init()
		return _recipes.get(id)
