extends Node

signal level_up(new_level: int, reward: String)
signal unlocks_changed
signal stock_changed

const LEVELS = [
	{"goal_item": "iron_ore", "required": 10, "reward": "unlock_smelter"},
	{"goal_item": "iron_ingot", "required": 20, "reward": "unlock_assembler"},
	{"goal_item": "iron_plate", "required": 30, "reward": "unlock_cutter_and_splitter"},
	{"goal_item": "iron_rod", "required": 30, "reward": "unlock_mixer"},
	{"goal_item": "screw", "required": 50, "reward": ""},
	# ここからは平原以外のバイオームの資源を運び込まないと達成できない
	{"goal_item": "copper_ingot", "required": 30, "reward": ""},
	{"goal_item": "steel", "required": 20, "reward": ""},
]

var level: int = 1
var gained_rewards: Dictionary = {}
var creative_mode: bool = false
# ハブに納品して貯めたアイテム。ピースの設置コストはここから支払う。 {item_id: 個数}
var stock: Dictionary = {}


func get_current_goal() -> Dictionary:
	var idx = level - 1
	if idx < LEVELS.size():
		return LEVELS[idx]
	return {"goal_item": "", "required": 0, "reward": ""}


func is_reward_unlocked(reward: String) -> bool:
	if creative_mode:
		return true
	if reward == "":
		return true
	return gained_rewards.get(reward, false)


# 進行度を最初の状態に戻す（新しいゲームの開始時）
func reset():
	level = 1
	gained_rewards = {}
	creative_mode = false
	stock = {}
	unlocks_changed.emit()
	stock_changed.emit()


func get_stock(item_id: String) -> int:
	return stock.get(item_id, 0)


func add_stock(item_id: String, amount: int) -> void:
	stock[item_id] = get_stock(item_id) + amount
	stock_changed.emit()


# クリエイティブモードでは在庫に関係なく何でも設置できる
func can_afford(cost: Dictionary) -> bool:
	if creative_mode:
		return true
	for item_id in cost:
		if get_stock(item_id) < cost[item_id]:
			return false
	return true


# 支払えたら true。足りなければ何も引かずに false。
func pay(cost: Dictionary) -> bool:
	if not can_afford(cost):
		return false
	if creative_mode or cost.is_empty():
		return true
	for item_id in cost:
		stock[item_id] = get_stock(item_id) - cost[item_id]
	stock_changed.emit()
	return true


# 撤去時の払い戻し。クリエイティブモードでは支払っていないので戻さない。
func refund(cost: Dictionary) -> void:
	if creative_mode or cost.is_empty():
		return
	for item_id in cost:
		stock[item_id] = get_stock(item_id) + cost[item_id]
	stock_changed.emit()


func toggle_creative_mode():
	creative_mode = not creative_mode
	unlocks_changed.emit()


func advance_level():
	var goal = get_current_goal()
	var reward = goal.get("reward", "")
	if reward != "":
		gained_rewards[reward] = true
	level += 1
	level_up.emit(level, reward)
