class_name Crafter
extends Node

## 機械の加工ロジック（shapez の ItemProcessor 相当）。
## 入力アイテムは Crafter 自身が入力スロット(_input_slots: Dictionary)で種別ごとに保持する
## （汎用 Inventory は使わない）。レシピに入力があるピースは Crafter が受け入れ口になる
## （get_acceptor が can_accept_item+add_item を持つ Crafter を返す。miner は入力容量0で受け付けない）。
## can_accept_item はレシピの inputs にない種別のアイテムを拒否する。
## 出力は ItemEjector のスロットへ。

# 加工開始済みを示す番兵値（processing_progress == 0.0 を「未開始」として区別するため）
const CRAFTING_START_PROGRESS = 0.001

var current_recipe: Recipe
var processing_progress: float = 0.0
var output_multiplier: int = 1
var input_capacity: int = 0

var output_container: Node

var _input_slots: Dictionary = {}  # {item_name: count}

@onready var _progress_bar: ProgressBar = get_node_or_null("ProgressBar")


func setup(out_container: Node):
	output_container = out_container


func set_recipe(recipe: Recipe):
	current_recipe = recipe
	processing_progress = 0.0
	_apply_io_capacities()


# 入出力容量を「1クラフト分」に絞る。入力が無いピース(miner)は input_capacity=0（受け付けない）。
func _apply_io_capacities():
	if not current_recipe:
		return
	input_capacity = _sum_quantities(current_recipe.inputs)
	if output_container and output_container.has_method("set_capacity"):
		output_container.set_capacity(maxi(_sum_quantities(current_recipe.outputs), 1))


func _sum_quantities(items: Dictionary) -> int:
	var total = 0
	for quantity in items.values():
		total += quantity
	return total


# --- 入力受け入れ口（shapez ItemAcceptor 相当をここに内包） ---
func can_accept_item(item_name: String) -> bool:
	if is_full():
		return false
	if not current_recipe:
		return false
	return current_recipe.inputs.has(item_name)


func add_item(item_name: String, amount: int):
	_input_slots[item_name] = _input_slots.get(item_name, 0) + amount


func consume_item(item_name: String, amount: int):
	if not _input_slots.has(item_name):
		return
	_input_slots[item_name] -= amount
	if _input_slots[item_name] <= 0:
		_input_slots.erase(item_name)


func get_item_count(item_name: String) -> int:
	return _input_slots.get(item_name, 0)


func is_full() -> bool:
	var total := 0
	for count in _input_slots.values():
		total += count
	return total >= input_capacity


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
		if processing_progress >= _effective_craft_time():
			_complete_crafting()

	if _progress_bar:
		_progress_bar.visible = processing_progress > 0
		_progress_bar.max_value = _effective_craft_time()
		_progress_bar.value = processing_progress


# output_multiplier は生産個数ではなく速度に作用する（鉱床が濃いほど速く加工）。
func _effective_craft_time() -> float:
	return current_recipe.craft_time / output_multiplier


func _can_start_crafting() -> bool:
	if not current_recipe:
		return false

	# アウトプットが満杯なら開始しない
	if output_container and output_container.is_full():
		return false

	# Inputsが空の場合はtrue (Miner)
	if current_recipe.inputs.is_empty():
		return true

	for item_name in current_recipe.inputs:
		if get_item_count(item_name) < current_recipe.inputs[item_name]:
			return false
	return true


func _start_crafting():
	for item_name in current_recipe.inputs:
		consume_item(item_name, current_recipe.inputs[item_name])
	processing_progress = CRAFTING_START_PROGRESS


func _complete_crafting():
	if output_container:
		for item_name in current_recipe.outputs:
			output_container.add_item(item_name, current_recipe.outputs[item_name])
	processing_progress = 0.0
