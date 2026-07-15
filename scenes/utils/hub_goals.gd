extends Node

signal level_up(new_level: int, reward: String)

const LEVELS = [
	{"goal_item": "iron_ore", "required": 10, "reward": "unlock_smelter"},
	{"goal_item": "iron_ingot", "required": 20, "reward": "unlock_assembler"},
	{"goal_item": "iron_plate", "required": 30, "reward": "unlock_cutter_and_splitter"},
	{"goal_item": "iron_rod", "required": 30, "reward": "unlock_mixer"},
	{"goal_item": "screw", "required": 50, "reward": ""},
]

var level: int = 1
var gained_rewards: Dictionary = {}
var creative_mode: bool = false


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


func advance_level():
	var goal = get_current_goal()
	var reward = goal.get("reward", "")
	if reward != "":
		gained_rewards[reward] = true
	level += 1
	level_up.emit(level, reward)
