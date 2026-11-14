class_name BuildCost
extends RefCounted

## ピースの設置に必要な素材。ハブに納品して貯めた在庫（HubGoals の stock）から支払う。
## ここに無いピース（コンベア・最初の採掘機・ハブ）は無料。
## 価格は仮の値。各ピースは、それが解放される時点で在庫にあるはずの素材で買えるようにしてある。

const PIECE_DIR := "res://scenes/components/piece/"

const COSTS = {
	PIECE_DIR + "smelter_t1.tscn": {"iron_ore": 5},
	PIECE_DIR + "assembler_t1.tscn": {"iron_ingot": 5},
	PIECE_DIR + "cutter_t1.tscn": {"iron_plate": 5},
	PIECE_DIR + "mixer_t1.tscn": {"iron_rod": 5},
	PIECE_DIR + "painter.tscn": {"iron_rod": 5},
	PIECE_DIR + "sender.tscn": {"iron_ingot": 5},
	PIECE_DIR + "receiver.tscn": {"iron_ingot": 5},
	# チェストはコンベア（無料）より高くして、何でもチェストで済ませられないようにする
	PIECE_DIR + "chest_in.tscn": {"iron_plate": 10},
	PIECE_DIR + "chest_out.tscn": {"iron_plate": 10},
	PIECE_DIR + "miner_t2.tscn": {"iron_plate": 10},
	PIECE_DIR + "smelter_t2.tscn": {"iron_plate": 10},
	PIECE_DIR + "assembler_t2.tscn": {"iron_rod": 10},
	PIECE_DIR + "cutter_t2.tscn": {"screw": 10},
	PIECE_DIR + "mixer_t2.tscn": {"screw": 10},
}


static func of_scene(scene: PackedScene) -> Dictionary:
	return COSTS.get(scene.resource_path, {}) if scene else {}


static func of_piece(piece: Node) -> Dictionary:
	return COSTS.get(piece.scene_file_path, {})


# 例: {"iron_ore": 5} → "Iron Ore 5"。無料なら「なし」。
static func to_text(cost: Dictionary) -> String:
	if cost.is_empty():
		return "なし"
	var parts: Array[String] = []
	for item_id in cost:
		var item = ItemDB.get_item(item_id)
		parts.append("%s %d" % [item.display_name if item else item_id, cost[item_id]])
	return "、".join(parts)
