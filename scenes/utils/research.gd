class_name Research
extends RefCounted

## 研究の定義。ハブに貯めた在庫を払って、速度の強化やチェストの解放を得る。
## 本筋に必須の機械はここには入れず、ハブのレベルで自動解放する（HubGoals.LEVELS）。
## 研究済みかどうかなどの進行状況は HubGoals が持つ（ここは変わらない定義だけ）。
##
## 各研究の項目:
##   name / description  表示用
##   cost                価格 {item_id: 個数}
##   level               研究できるようになるハブのレベル（HubGoals.level がこの値以上）
##   requires            先に済ませておく研究の id（同じ系統の研究にする。ツリーで横一列につなぐため）
##   branch              系統（BRANCHES のどれか）。ツリー画面の行になる
##   effect              効果。{"unlock": 報酬id} / {"belt_speed": 倍率} / {"mining_speed": 倍率}
##                       / {"skill": スキルid}（SkillLibrary.RESEARCH_SKILLS の戦闘スキル）
##   conditions          探索の条件（省略可）。{"chunks": 所有している chunk の数}
##                       / {"biome": そのバイオームの chunk を1つ以上持っていること}
## 価格は仮の値。

enum State { DONE, AVAILABLE, UNAFFORDABLE, LOCKED_PREREQUISITE, LOCKED_LEVEL, LOCKED_CONDITION }

const BELT_SPEED := "belt_speed"
const MINING_SPEED := "mining_speed"
const UNLOCK := "unlock"
const SKILL := "skill"
const CHUNKS := "chunks"
const BIOME := "biome"

# 系統。ツリー画面では上からこの順に行を並べる
const LOGISTICS := "logistics"
const MINING := "mining"
const CHEST := "chest"
const COMBAT := "combat"
const BRANCHES := [LOGISTICS, MINING, CHEST, COMBAT]
const _BRANCH_NAMES := {LOGISTICS: "物流", MINING: "採掘", CHEST: "チェスト", COMBAT: "戦闘"}

# 一覧に表示する順（おおむね研究できるようになる順）
const DEFS = {
	"mining_speed_1":
	{
		"branch": MINING,
		"name": "採掘高速化 I",
		"description": "すべての採掘機が1.5倍の速さで掘る。",
		"cost": {"iron_ore": 20},
		"level": 2,
		"requires": [],
		"effect": {MINING_SPEED: 1.5},
	},
	"belt_speed_1":
	{
		"branch": LOGISTICS,
		"name": "コンベア高速化 I",
		"description": "すべてのコンベアが2倍の速さで運ぶ（毎分120個）。",
		"cost": {"iron_ingot": 20},
		"level": 3,
		"requires": [],
		"effect": {BELT_SPEED: 2.0},
	},
	"unlock_chunk_chest":
	{
		"branch": CHEST,
		"name": "Chunk チェスト",
		"description": "同じ chunk の中で中身を共有するチェスト（搬入・搬出）を設置できるようになる。",
		"cost": {"iron_plate": 20},
		"level": 4,
		"requires": [],
		"effect": {UNLOCK: "unlock_chunk_chest"},
	},
	"mining_speed_2":
	{
		"branch": MINING,
		"name": "採掘高速化 II",
		"description": "すべての採掘機が2倍の速さで掘る。",
		"cost": {"iron_plate": 20},
		"level": 4,
		"requires": ["mining_speed_1"],
		"effect": {MINING_SPEED: 2.0},
	},
	"skill_iron_wall":
	{
		"branch": COMBAT,
		"name": "戦闘: 鉄壁",
		"description": "戦闘で「鉄壁」（防御 8、2ターンに1回）が使えるようになる。",
		"cost": {"iron_plate": 20},
		"level": 4,
		"requires": [],
		"effect": {SKILL: "iron_wall"},
	},
	"belt_speed_2":
	{
		"branch": LOGISTICS,
		"name": "コンベア高速化 II",
		"description": "すべてのコンベアが4倍の速さで運ぶ（毎分240個）。",
		"cost": {"screw": 20},
		"level": 5,
		"requires": ["belt_speed_1"],
		"effect": {BELT_SPEED: 4.0},
	},
	"belt_speed_3":
	{
		"branch": LOGISTICS,
		"name": "コンベア高速化 III",
		"description": "すべてのコンベアが8倍の速さで運ぶ（毎分480個）。",
		"cost": {"circuit": 20},
		"level": 8,
		"requires": ["belt_speed_2"],
		"effect": {BELT_SPEED: 8.0},
	},
	"unlock_biome_chest":
	{
		"branch": CHEST,
		"name": "Biome チェスト",
		"description": "同じバイオームのひと続きの地域の中で中身を共有するチェスト（搬入・搬出）を設置できるようになる。",
		"cost": {"concrete": 20},
		"level": 8,
		"requires": ["unlock_chunk_chest"],
		"effect": {UNLOCK: "unlock_biome_chest"},
	},
	"skill_steel_lance":
	{
		"branch": COMBAT,
		"name": "戦闘: 鋼の槍",
		"description": "戦闘で「鋼の槍」（攻撃 6、毎ターン1回）が使えるようになる。",
		"cost": {"steel": 20},
		"level": 7,
		"requires": [],
		"conditions": {BIOME: Biome.FOREST},
		"effect": {SKILL: "steel_lance"},
	},
	"skill_sprint":
	{
		"branch": COMBAT,
		"name": "戦闘: 疾走",
		"description": "戦闘で「疾走」（6マス移動、2ターンに1回）が使えるようになる。",
		"cost": {"motor": 10},
		"level": 9,
		"requires": [],
		"conditions": {CHUNKS: 3},
		"effect": {SKILL: "sprint"},
	},
	"unlock_planet_chest":
	{
		"branch": CHEST,
		"name": "Planet チェスト",
		"description": "惑星のどの chunk に置いても中身を共有するチェスト（搬入・搬出）を設置できるようになる。",
		"cost": {"steel": 30, "copper_ingot": 30},
		"level": 10,
		"requires": ["unlock_biome_chest"],
		"effect": {UNLOCK: "unlock_planet_chest"},
	},
}


static func branch_name(branch: String) -> String:
	return _BRANCH_NAMES.get(branch, "")


static func all_ids() -> Array:
	return DEFS.keys()


# 存在しない id なら空の Dictionary
static func get_def(id: String) -> Dictionary:
	return DEFS.get(id, {})
