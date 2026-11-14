class_name Research
extends RefCounted

## 研究の定義。ハブに貯めた在庫を払って、ピースの解放や速度の強化を得る。
## 研究済みかどうかなどの進行状況は HubGoals が持つ（ここは変わらない定義だけ）。
##
## 各研究の項目:
##   name / description  表示用
##   cost                価格 {item_id: 個数}
##   level               研究できるようになるハブのレベル（HubGoals.level がこの値以上）
##   requires            先に済ませておく研究の id
##   effect              効果。{"unlock": 報酬id} / {"belt_speed": 倍率} / {"mining_speed": 倍率}
## 価格は仮の値。

enum State { DONE, AVAILABLE, UNAFFORDABLE, LOCKED_PREREQUISITE, LOCKED_LEVEL }

const BELT_SPEED := "belt_speed"
const MINING_SPEED := "mining_speed"
const UNLOCK := "unlock"

# 一覧に表示する順（おおむね研究できるようになる順）
const DEFS = {
	"mining_speed_1":
	{
		"name": "採掘高速化 I",
		"description": "すべての採掘機が1.5倍の速さで掘る。",
		"cost": {"iron_ore": 20},
		"level": 2,
		"requires": [],
		"effect": {MINING_SPEED: 1.5},
	},
	"unlock_assembler":
	{
		"name": "Assembler",
		"description": "Assembler を設置できるようになる。",
		"cost": {"iron_ingot": 10},
		"level": 3,
		"requires": [],
		"effect": {UNLOCK: "unlock_assembler"},
	},
	"belt_speed_1":
	{
		"name": "コンベア高速化 I",
		"description": "すべてのコンベアが1.5倍の速さで運ぶ。",
		"cost": {"iron_ingot": 20},
		"level": 3,
		"requires": [],
		"effect": {BELT_SPEED: 1.5},
	},
	"unlock_cutter":
	{
		"name": "Cutter",
		"description": "Cutter を設置できるようになる。",
		"cost": {"iron_plate": 10},
		"level": 4,
		"requires": [],
		"effect": {UNLOCK: "unlock_cutter_and_splitter"},
	},
	"unlock_chunk_chest":
	{
		"name": "Chunk チェスト",
		"description": "同じ chunk の中で中身を共有するチェスト（搬入・搬出）を設置できるようになる。",
		"cost": {"iron_plate": 20},
		"level": 4,
		"requires": [],
		"effect": {UNLOCK: "unlock_chunk_chest"},
	},
	"mining_speed_2":
	{
		"name": "採掘高速化 II",
		"description": "すべての採掘機が2倍の速さで掘る。",
		"cost": {"iron_plate": 20},
		"level": 4,
		"requires": ["mining_speed_1"],
		"effect": {MINING_SPEED: 2.0},
	},
	"unlock_mixer":
	{
		"name": "Mixer と Painter",
		"description": "Mixer と Painter を設置できるようになる。",
		"cost": {"iron_rod": 10},
		"level": 5,
		"requires": [],
		"effect": {UNLOCK: "unlock_mixer"},
	},
	"belt_speed_2":
	{
		"name": "コンベア高速化 II",
		"description": "すべてのコンベアが2倍の速さで運ぶ。",
		"cost": {"screw": 20},
		"level": 5,
		"requires": ["belt_speed_1"],
		"effect": {BELT_SPEED: 2.0},
	},
	"unlock_biome_chest":
	{
		"name": "Biome チェスト",
		"description": "同じバイオームのひと続きの地域の中で中身を共有するチェスト（搬入・搬出）を設置できるようになる。",
		"cost": {"screw": 20},
		"level": 6,
		"requires": ["unlock_chunk_chest"],
		"effect": {UNLOCK: "unlock_biome_chest"},
	},
	"unlock_planet_chest":
	{
		"name": "Planet チェスト",
		"description": "惑星のどの chunk に置いても中身を共有するチェスト（搬入・搬出）を設置できるようになる。",
		"cost": {"steel": 30, "copper_ingot": 30},
		"level": 8,
		"requires": ["unlock_biome_chest"],
		"effect": {UNLOCK: "unlock_planet_chest"},
	},
}


static func all_ids() -> Array:
	return DEFS.keys()


# 存在しない id なら空の Dictionary
static func get_def(id: String) -> Dictionary:
	return DEFS.get(id, {})
