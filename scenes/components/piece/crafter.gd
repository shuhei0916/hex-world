class_name Crafter
extends Node

# 加工開始済みを示す番兵値（processing_progress == 0.0 を「未開始」として区別するため）
const CRAFTING_START_PROGRESS = 0.001

var current_recipe: Recipe
var processing_progress: float = 0.0

var input_container: Node
var output_container: Node

@onready var _progress_bar: ProgressBar = get_node_or_null("ProgressBar")


func setup(in_container: Node, out_container: Node):
	input_container = in_container
	output_container = out_container


func set_recipe(recipe: Recipe):
	current_recipe = recipe
	processing_progress = 0.0


func start_crafting():
	# 手動開始用（テストなどで使用）
	processing_progress = CRAFTING_START_PROGRESS


func tick(delta: float):
	if not current_recipe:
		if _progress_bar:
			_progress_bar.visible = false
		return

	# 未開始なら開始を試みる
	if processing_progress == 0.0:
		if _can_start_crafting():
			_start_crafting()

	# 加工中なら進捗を進める
	if processing_progress > 0.0:
		processing_progress += delta
		if processing_progress >= current_recipe.craft_time:
			_complete_crafting()

	if _progress_bar:
		_progress_bar.visible = processing_progress > 0
		_progress_bar.max_value = current_recipe.craft_time
		_progress_bar.value = processing_progress


func _can_start_crafting() -> bool:
	if not current_recipe:
		return false

	# アウトプットインベントリが満杯なら開始しない
	if output_container and output_container.is_full():
		return false

	# Inputsが空の場合はtrue (Miner)
	if current_recipe.inputs.is_empty():
		return true

	if not input_container:
		return false

	for item_name in current_recipe.inputs:
		if input_container.get_item_count(item_name) < current_recipe.inputs[item_name]:
			return false
	return true


func _start_crafting():
	if input_container:
		for item_name in current_recipe.inputs:
			input_container.consume_item(item_name, current_recipe.inputs[item_name])
	processing_progress = CRAFTING_START_PROGRESS
	if output_container is Output and not current_recipe.outputs.is_empty():
		output_container.set_expected_output(current_recipe.outputs.keys()[0])


func _complete_crafting():
	if output_container is Output:
		output_container.set_expected_output("")
	if output_container:
		for item_name in current_recipe.outputs:
			output_container.add_item(item_name, current_recipe.outputs[item_name])
	processing_progress = 0.0
