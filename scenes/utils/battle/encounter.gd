class_name Encounter
## ランの各戦闘の戦場と敵を作る。

## 1ランの戦闘の数。最後の戦闘はボス戦。
const STAGE_COUNT := 5
const RADIUS := 4
const PLAYER_START := Vector2i(-3, 1)
## 敵を置くときに主人公から最低限あける距離。
const MIN_ENEMY_DISTANCE := 4
const MIN_WALLS := 4
const MAX_WALLS := 7

## 戦闘ごとの敵の [最大HP, 攻撃力] の一覧。
const ENEMIES_BY_STAGE: Array[Array] = [
	[[5, 2], [5, 2]],
	[[5, 2], [5, 2], [5, 2]],
	[[8, 3], [5, 2], [5, 2]],
	[[8, 3], [8, 3], [5, 2], [5, 2]],
	[[24, 4], [5, 2], [5, 2]],
]


## stage 番目（1始まり）の戦闘を作り、player を開始位置に置く。
static func generate(stage: int, player: Unit, rng: RandomNumberGenerator) -> Battle:
	var field := Battlefield.hexagon(RADIUS)
	_place_walls(field, rng)
	field.place_unit(player, PLAYER_START)
	var spots: Array[Vector2i] = field.cells().filter(
		func(hex: Vector2i) -> bool:
			return (
				field.is_walkable(hex)
				and BattleHex.distance(hex, PLAYER_START) >= MIN_ENEMY_DISTANCE
			)
	)
	Shuffle.in_place(spots, rng)
	var specs: Array = ENEMIES_BY_STAGE[stage - 1]
	for i in range(specs.size()):
		field.place_unit(Unit.new(Unit.Team.ENEMY, specs[i][0], specs[i][1]), spots[i])
	return Battle.new(field)


## 壁を乱数で置く。床が分断される置き方は取り消す。
static func _place_walls(field: Battlefield, rng: RandomNumberGenerator) -> void:
	var candidates: Array[Vector2i] = field.cells().filter(
		func(hex: Vector2i) -> bool: return BattleHex.distance(hex, PLAYER_START) > 1
	)
	Shuffle.in_place(candidates, rng)
	var wanted := rng.randi_range(MIN_WALLS, MAX_WALLS)
	var floor_count := field.cells().size()
	for hex in candidates:
		if wanted == 0:
			return
		field.set_terrain(hex, Battlefield.Terrain.WALL)
		if field.reachable(PLAYER_START, floor_count).size() == floor_count - 1:
			floor_count -= 1
			wanted -= 1
		else:
			field.set_terrain(hex, Battlefield.Terrain.FLOOR)
