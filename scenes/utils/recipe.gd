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
		for resource_type in ["iron_ore", "copper_ore", "coal", "sand", "limestone"]:
			register_recipe(
				Recipe.new(resource_type, {}, {resource_type: 1}, 1.0), PieceData.Type.MINER
			)

		# docs/recipe_plan.md のレシピ表。[機械, 材料, 出力, 秒]
		# 機械は届いた材料からレシピを選ぶので、同じ機械のレシピ同士で材料が重ならないように配る
		for row in [
			# Smelter（1入力）: 溶かす
			[PieceData.Type.SMELTER, {"iron_ore": 1}, {"iron_ingot": 1}, 2.0],
			[PieceData.Type.SMELTER, {"copper_ore": 1}, {"copper_ingot": 1}, 2.0],
			[PieceData.Type.SMELTER, {"sand": 2}, {"glass": 1}, 3.0],
			# Cutter（1入力）: 1つの素材の形を変える
			[PieceData.Type.CUTTER, {"iron_ingot": 1}, {"iron_plate": 1}, 3.0],
			[PieceData.Type.CUTTER, {"iron_plate": 1}, {"screw": 2}, 3.0],
			[PieceData.Type.CUTTER, {"copper_ingot": 1}, {"copper_wire": 2}, 3.0],
			[PieceData.Type.CUTTER, {"steel": 1}, {"steel_beam": 1}, 4.0],
			[PieceData.Type.CUTTER, {"glass": 1}, {"lens": 1}, 4.0],
			# Mixer（2入力）: 混ぜる・組み合わせる
			[PieceData.Type.MIXER, {"iron_ingot": 1, "coal": 1}, {"steel": 1}, 4.0],
			[PieceData.Type.MIXER, {"copper_wire": 2, "iron_plate": 1}, {"circuit": 1}, 6.0],
			[PieceData.Type.MIXER, {"steel_beam": 2, "screw": 2}, {"frame": 1}, 6.0],
			[PieceData.Type.MIXER, {"lens": 1, "circuit": 1}, {"sensor": 1}, 8.0],
			[PieceData.Type.MIXER, {"quicklime": 1, "sand": 2}, {"concrete": 1}, 4.0],
			# Kiln（1入力）: 焼く
			[PieceData.Type.KILN, {"limestone": 1}, {"quicklime": 1}, 3.0],
			# Assembler（2入力）: 部品を組み立てる
			[PieceData.Type.ASSEMBLER, {"iron_plate": 1, "screw": 2}, {"gear": 1}, 4.0],
			[PieceData.Type.ASSEMBLER, {"gear": 1, "copper_wire": 2}, {"motor": 1}, 6.0],
			[PieceData.Type.ASSEMBLER, {"frame": 1, "motor": 1}, {"engine": 1}, 8.0],
			[PieceData.Type.ASSEMBLER, {"sensor": 1, "engine": 1}, {"probe": 1}, 12.0],
		]:
			var output: String = row[2].keys()[0]
			register_recipe(Recipe.new(output, row[1], row[2], row[3]), row[0])

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
