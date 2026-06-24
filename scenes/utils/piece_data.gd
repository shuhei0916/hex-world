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
}

# 各 Type に対応するアンロック報酬キー。"" は常時アンロック。
const UNLOCK_REWARDS: Dictionary = {
	Type.CONVEYOR: "",
	Type.MINER: "",
	Type.HUB: "",
	Type.CHEST: "",
	Type.SMELTER: "unlock_smelter",
	Type.ASSEMBLER: "unlock_assembler",
	Type.CUTTER: "unlock_cutter_and_splitter",
	Type.MIXER: "unlock_mixer",
	Type.PAINTER: "unlock_mixer",
}


static func is_unlocked(type: Type) -> bool:
	var reward: String = UNLOCK_REWARDS.get(type, "")
	return HubGoals.is_reward_unlocked(reward)
