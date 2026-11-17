class_name Encounter
## 1戦ぶんの戦場を作り、主人公と敵を置く。戦場の大きさと壁は呼び出し側が決める。

## 敵の強さの段階の数。最後の段階はボス戦。
const STAGE_COUNT := 5
## 敵を置くときに主人公から最低限あける距離。
const MIN_ENEMY_DISTANCE := 4

## 段階ごとの敵の [最大HP, 攻撃力] の一覧。
const ENEMIES_BY_STAGE: Array[Array] = [
	[[5, 2], [5, 2]],
	[[5, 2], [5, 2], [5, 2]],
	[[8, 3], [5, 2], [5, 2]],
	[[8, 3], [8, 3], [5, 2], [5, 2]],
	[[24, 4], [5, 2], [5, 2]],
]


## 半径 radius の戦場で主人公が始まるマス。左下の端の近く。
static func player_start(radius: int) -> Vector2i:
	@warning_ignore("integer_division")
	return Vector2i(1 - radius, radius / 2)


## 半径 radius の六角形の戦場に、stage 番目（1始まり）の段階の敵と player を置く。
## walls のマスは通れない壁になる（戦場の外のマスは無視する）。
static func generate(
	stage: int, player: Unit, rng: RandomNumberGenerator, radius: int, walls: Array[Vector2i] = []
) -> Battle:
	var field := Battlefield.hexagon(radius)
	for hex in walls:
		if field.has_cell(hex):
			field.set_terrain(hex, Battlefield.Terrain.WALL)
	var start := _nearest_walkable(field, player_start(radius))
	field.place_unit(player, start)
	var spots: Array[Vector2i] = field.cells().filter(
		func(hex: Vector2i) -> bool:
			return field.is_walkable(hex) and Hex.distance(hex, start) >= MIN_ENEMY_DISTANCE
	)
	# 辞書の並び順に左右されないよう、並べてから混ぜる
	spots.sort()
	Shuffle.in_place(spots, rng)
	var specs: Array = ENEMIES_BY_STAGE[stage - 1]
	for i in range(specs.size()):
		field.place_unit(Unit.new(Unit.Team.ENEMY, specs[i][0], specs[i][1]), spots[i])
	return Battle.new(field)


## from にいちばん近い、歩けるマス。from が歩けるならそのまま返す。
static func _nearest_walkable(field: Battlefield, from: Vector2i) -> Vector2i:
	var cells := field.cells()
	cells.sort()
	var best := from
	var best_distance := -1
	for hex in cells:
		if not field.is_walkable(hex):
			continue
		var distance := Hex.distance(hex, from)
		if best_distance < 0 or distance < best_distance:
			best = hex
			best_distance = distance
	return best
