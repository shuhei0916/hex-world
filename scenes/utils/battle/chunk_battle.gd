class_name ChunkBattle
## chunk を解放するための1戦を作る。その chunk のマスがそのまま戦場になり、鉱床は通れない壁になる。
## 原点から遠い chunk ほど敵が手ごわい。
## 主人公は毎回 HP が満タンの状態で、最初から使えるスキルで戦う。

const PLAYER_MAX_HP := 30
const PLAYER_ATTACK := 3


## chunk_hex の戦闘が、何番目の段階（1始まり）の敵になるか。
static func stage_for(chunk_hex: Hex) -> int:
	return clampi(Hex.length(chunk_hex), 1, Encounter.STAGE_COUNT)


## chunk_hex にある chunk の上で行う戦闘を作る。
static func create(chunk_hex: Hex, chunk: Chunk, rng: RandomNumberGenerator) -> SkillTurn:
	var player := Unit.new(Unit.Team.PLAYER, PLAYER_MAX_HP, PLAYER_ATTACK)
	var battle := Encounter.generate(
		stage_for(chunk_hex), player, rng, chunk.grid_radius, walls_of(chunk)
	)
	return SkillTurn.new(battle, SkillLibrary.starter_skills())


## chunk のマスのうち、戦闘で通れないもの（鉱床）。
static func walls_of(chunk: Chunk) -> Array[Vector2i]:
	var walls: Array[Vector2i] = []
	for hex in chunk.get_all_hexes():
		if chunk.get_hex_resource(hex) != "":
			walls.append(BattleHex.from_hex(hex))
	return walls
