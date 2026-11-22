class_name PlayerCharacter
extends RefCounted
## プレイヤーキャラクター。どの chunk の、どの位置に立っているかを持つ。
## 戦闘の主人公と同じ1人で、ふだんは工場のある世界をマスに縛られず自由に歩く
## （戦闘ではマス単位で動く）。立っているマス hex は位置から決まる。

## ハブの位置。新しいゲームではこの隣に現れる
const HUB_HEX := Vector2i(0, 0)
## 上を歩けるピース
const WALKABLE_PIECES := [PieceData.Type.CONVEYOR, PieceData.Type.BRIDGE]
## 体の半径（chunk の中のピクセル）。体のどこかが通れないマスにかかる位置には立てない
const BODY_RADIUS := 18.0
## 体の縁のうち、通れるかを確かめる点の数
const BODY_SAMPLES := 8
## 押し出すとき、何ピクセルずつ遠くを試すか・何方向を試すか・どこまで試すか。
## それより遠くにしか立てる位置が無ければ、立てるマスの中心へ移す
const PUSH_STEP := 1.0
const PUSH_DIRECTIONS := 72
const PUSH_MAX_DISTANCE := 120.0

var chunk_hex: Vector2i
## chunk の中の位置（ピクセル。chunk の中心が原点）
var position: Vector2
## 立っているマス
var hex: Vector2i:
	get:
		return Layout.pixel_to_hex_rounded(_layout(), position)
	set(value):
		position = Layout.hex_to_pixel(_layout(), value)


func _init(p_chunk_hex: Vector2i, p_hex: Vector2i) -> void:
	chunk_hex = p_chunk_hex
	hex = p_hex


static func _layout() -> Layout:
	return Layout.make_default()


## chunk の hex のマスに入れるか。chunk の中で、何も無いか、上を歩けるコンベアや橋のマスだけ。
## 鉱床は通れる。blocked のマス（これからピースを置くマスなど）は通れないものとして扱う。
static func can_enter(chunk: Chunk, target: Vector2i, blocked: Array = []) -> bool:
	if not chunk.is_inside_grid(target) or target in blocked:
		return false
	var piece := chunk.get_piece_at_hex(target)
	return piece == null or piece.piece_type in WALKABLE_PIECES


## chunk の中の位置 pos に立てるか。体の中心と縁が、すべて入れるマスの上にあるときだけ。
static func can_stand_at(chunk: Chunk, pos: Vector2, blocked: Array = []) -> bool:
	if not can_enter(chunk, Layout.pixel_to_hex_rounded(chunk.layout, pos), blocked):
		return false
	for i in range(BODY_SAMPLES):
		var edge := pos + Vector2.from_angle(TAU * i / BODY_SAMPLES) * BODY_RADIUS
		if not can_enter(chunk, Layout.pixel_to_hex_rounded(chunk.layout, edge), blocked):
			return false
	return true


## blocked のマスに上を歩けないピースを置くとき、位置 pos のキャラクターが立つ位置。
## 重ならなければ pos のまま。重なるなら、最小の距離だけ押し出して施設の端に体が接する位置にする
## （歩いてぶつかったときに止まる位置と同じ判定）。同じ距離なら、置くマスの中心から離れる向きを選ぶ。
## 近くに無ければ、立てるマスのうちいちばん近いマスの中心。どこにも無ければ null
static func push_out_position(chunk: Chunk, pos: Vector2, blocked: Array):
	if can_stand_at(chunk, pos, blocked):
		return pos
	var away := pos - _center_of(chunk, blocked)
	var distance := PUSH_STEP
	while distance <= PUSH_MAX_DISTANCE:
		var best = null
		var best_score := -INF
		for i in range(PUSH_DIRECTIONS):
			var direction := Vector2.from_angle(TAU * i / PUSH_DIRECTIONS)
			var candidate := pos + direction * distance
			if can_stand_at(chunk, candidate, blocked) and direction.dot(away) > best_score:
				best = candidate
				best_score = direction.dot(away)
		if best != null:
			return best
		distance += PUSH_STEP
	return _nearest_standable_center(chunk, pos, blocked)


## hexes の中心の平均（chunk の中のピクセル）
static func _center_of(chunk: Chunk, hexes: Array) -> Vector2:
	var sum := Vector2.ZERO
	for hex in hexes:
		sum += chunk.hex_to_pixel(hex)
	return sum / maxi(hexes.size(), 1)


## 立てるマスのうち、pos にいちばん近いマスの中心。どこにも無ければ null
static func _nearest_standable_center(chunk: Chunk, pos: Vector2, blocked: Array):
	var best = null
	for hex in chunk.get_all_hexes():
		var center := chunk.hex_to_pixel(hex)
		if not can_stand_at(chunk, center, blocked):
			continue
		if best == null or center.distance_squared_to(pos) < best.distance_squared_to(pos):
			best = center
	return best


## chunk で最初に立つマス。ハブの隣のうち、施設の置かれていない最初のマス。
## すべてふさがっていればハブの東隣。
static func spawn_hex(chunk: Chunk) -> Vector2i:
	for candidate in Hex.neighbors(HUB_HEX):
		if chunk.is_inside_grid(candidate) and not chunk.is_occupied(candidate):
			return candidate
	return Hex.neighbor(HUB_HEX, 0)
