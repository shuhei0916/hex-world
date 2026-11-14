class_name PieceData
extends RefCounted

enum Type {
	CONVEYOR,
	SMELTER,
	CUTTER,
	MIXER,
	PAINTER,
	MINER,
	ASSEMBLER,
	CHEST,
	HUB,
	BRIDGE,
	RETIRED_RECEIVER,  # 廃止（橋が直接受け取り先へ渡す）。後ろの番号を変えないための欠番
	CHEST_OUT,
	PLANET_CHEST,
	PLANET_CHEST_OUT,
	BIOME_CHEST,
	BIOME_CHEST_OUT,
}

# 各 Type に対応するアンロック報酬キー。"" は常時アンロック。
const UNLOCK_REWARDS: Dictionary = {
	Type.CONVEYOR: "",
	Type.MINER: "",
	Type.HUB: "",
	Type.CHEST: "unlock_chunk_chest",
	Type.CHEST_OUT: "unlock_chunk_chest",
	Type.BIOME_CHEST: "unlock_biome_chest",
	Type.BIOME_CHEST_OUT: "unlock_biome_chest",
	Type.PLANET_CHEST: "unlock_planet_chest",
	Type.PLANET_CHEST_OUT: "unlock_planet_chest",
	Type.SMELTER: "unlock_smelter",
	Type.ASSEMBLER: "unlock_assembler",
	Type.CUTTER: "unlock_cutter_and_splitter",
	Type.MIXER: "unlock_mixer",
	Type.PAINTER: "unlock_mixer",
	Type.BRIDGE: "",
}


static func is_unlocked(type: Type) -> bool:
	var reward: String = UNLOCK_REWARDS.get(type, "")
	return HubGoals.is_reward_unlocked(reward)
