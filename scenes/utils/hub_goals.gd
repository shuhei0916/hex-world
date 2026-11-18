extends Node

signal level_up(new_level: int, reward: String)
signal unlocks_changed
signal stock_changed
signal research_changed
signal exploration_changed

const LEVELS = [
	# 本筋に必須の機械は、目標を納めると自動で解放する。
	# 取らなくても進める強化とチェストは、研究（Research）で在庫を払って得る。
	# 段階1: 平原（鉄）だけで達成できる
	{"goal_item": "iron_ore", "required": 10, "reward": "unlock_smelter"},
	{"goal_item": "iron_ingot", "required": 20, "reward": "unlock_cutter_and_splitter"},
	{"goal_item": "iron_plate", "required": 30, "reward": "unlock_assembler"},
	{"goal_item": "gear", "required": 20, "reward": "unlock_mixer"},
	# 段階2: 2つのバイオームの資源を組み合わせる
	{"goal_item": "copper_wire", "required": 40, "reward": ""},
	{"goal_item": "steel", "required": 20, "reward": ""},
	{"goal_item": "circuit", "required": 30, "reward": "unlock_kiln"},
	# 石灰岩の台地の石灰石を窯で焼き、砂と混ぜる。上位のチェストの材料になる
	{"goal_item": "concrete", "required": 30, "reward": ""},
	{"goal_item": "motor", "required": 20, "reward": ""},
	{"goal_item": "glass", "required": 30, "reward": ""},
	# 段階3: 3〜4つのバイオームの資源を組み合わせる。最終目標は探査機
	{"goal_item": "sensor", "required": 20, "reward": ""},
	{"goal_item": "engine", "required": 20, "reward": ""},
	{"goal_item": "probe", "required": 5, "reward": ""},
]

var level: int = 1
var gained_rewards: Dictionary = {}
var creative_mode: bool = false
# ハブに納品して貯めたアイテム。ピースの設置コストはここから支払う。 {item_id: 個数}
var stock: Dictionary = {}
# 研究済みの研究 {research_id: true}
var researched: Dictionary = {}
# 所有している chunk の数をバイオームごとに {biome_id: 数}。研究の条件に使う。
# 正は World の Territory で、Main が変わるたびに伝える（セーブには入れない）
var owned_chunks: Dictionary = {}


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
	if gained_rewards.get(reward, false):
		return true
	for id in researched:
		if Research.get_def(id).get("effect", {}).get(Research.UNLOCK, "") == reward:
			return true
	return false


# 進行度を最初の状態に戻す（新しいゲームの開始時）
func reset():
	level = 1
	gained_rewards = {}
	creative_mode = false
	stock = {}
	researched = {}
	owned_chunks = {}
	unlocks_changed.emit()
	stock_changed.emit()
	research_changed.emit()
	exploration_changed.emit()


func set_owned_chunks(counts: Dictionary) -> void:
	owned_chunks = counts.duplicate()
	exploration_changed.emit()


func owned_chunk_count() -> int:
	var total := 0
	for count in owned_chunks.values():
		total += count
	return total


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


# ---- 研究 -------------------------------------------------------------------


func is_researched(id: String) -> bool:
	return researched.has(id)


func research_state(id: String) -> Research.State:
	var def = Research.get_def(id)
	if is_researched(id):
		return Research.State.DONE
	if level < def.get("level", 0):
		return Research.State.LOCKED_LEVEL
	for required in def.get("requires", []):
		if not is_researched(required):
			return Research.State.LOCKED_PREREQUISITE
	if not _meets_conditions(def.get("conditions", {})):
		return Research.State.LOCKED_CONDITION
	if not can_afford(def.get("cost", {})):
		return Research.State.UNAFFORDABLE
	return Research.State.AVAILABLE


# 研究できない理由などを一言で表す。研究できる状態なら空文字。
func research_state_text(id: String) -> String:
	var def = Research.get_def(id)
	match research_state(id):
		Research.State.DONE:
			return "研究済み"
		Research.State.LOCKED_LEVEL:
			return "ハブ Lv%d で研究できる" % def["level"]
		Research.State.LOCKED_PREREQUISITE:
			for required in def["requires"]:
				if not is_researched(required):
					return "先に「%s」が必要" % Research.get_def(required)["name"]
		Research.State.LOCKED_CONDITION:
			return _condition_text(def["conditions"])
		Research.State.UNAFFORDABLE:
			return "在庫不足"
	return ""


func _meets_conditions(conditions: Dictionary) -> bool:
	if owned_chunk_count() < conditions.get(Research.CHUNKS, 0):
		return false
	var biome_id: String = conditions.get(Research.BIOME, "")
	return biome_id == "" or owned_chunks.get(biome_id, 0) > 0


# 満たしていない条件を文章にする（複数あれば「、」でつなぐ）
func _condition_text(conditions: Dictionary) -> String:
	var parts: Array[String] = []
	var needed: int = conditions.get(Research.CHUNKS, 0)
	if owned_chunk_count() < needed:
		parts.append("chunk を %d 個持つと研究できる（%d/%d）" % [needed, owned_chunk_count(), needed])
	var biome_id: String = conditions.get(Research.BIOME, "")
	if biome_id != "" and owned_chunks.get(biome_id, 0) == 0:
		parts.append("%s の chunk を持つと研究できる" % Biome.get_biome(biome_id).display_name)
	return "、".join(parts)


# 在庫から価格を払って研究する。条件を満たさなければ何もせず false。
func research(id: String) -> bool:
	if Research.get_def(id).is_empty() or research_state(id) != Research.State.AVAILABLE:
		return false
	var def = Research.get_def(id)
	pay(def["cost"])
	researched[id] = true
	research_changed.emit()
	if def["effect"].has(Research.UNLOCK):
		unlocks_changed.emit()
	return true


# 研究で解放した戦闘スキルの id（研究の定義の順）
func unlocked_skill_ids() -> Array:
	var ids := []
	for id in Research.all_ids():
		if is_researched(id) and Research.get_def(id)["effect"].has(Research.SKILL):
			ids.append(Research.get_def(id)["effect"][Research.SKILL])
	return ids


func get_belt_speed() -> float:
	return _best_effect(Research.BELT_SPEED)


func get_mining_speed() -> float:
	return _best_effect(Research.MINING_SPEED)


# 研究済みの研究のうち、その効果の最大の倍率（無ければ等倍）
func _best_effect(effect_key: String) -> float:
	var best := 1.0
	for id in researched:
		best = maxf(best, Research.get_def(id).get("effect", {}).get(effect_key, 1.0))
	return best
