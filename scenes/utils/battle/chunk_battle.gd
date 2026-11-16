class_name ChunkBattle
## chunk を解放するための1戦を作る。原点から遠い chunk ほど敵が手ごわい。
## 主人公は毎回 HP が満タンの状態で、最初から持っているデッキで戦う。

const PLAYER_MAX_HP := 30
const PLAYER_ATTACK := 3


## chunk_hex の戦闘が、何番目の段階（1始まり）の敵になるか。
static func stage_for(chunk_hex: Hex) -> int:
	return clampi(Hex.length(chunk_hex), 1, Encounter.STAGE_COUNT)


static func create(chunk_hex: Hex, rng: RandomNumberGenerator) -> CardTurn:
	var player := Unit.new(Unit.Team.PLAYER, PLAYER_MAX_HP, PLAYER_ATTACK)
	var battle := Encounter.generate(stage_for(chunk_hex), player, rng)
	return CardTurn.new(battle, Deck.new(CardLibrary.starter_cards(), rng))
