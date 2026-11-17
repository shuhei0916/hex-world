class_name PlayerCharacter
extends RefCounted
## プレイヤーキャラクター。どの chunk の、どのマスに立っているかを持つ。
## 戦闘の主人公と同じ1人で、ふだんは工場のある世界を歩く。

## ハブの位置。新しいゲームではこの隣に現れる
const HUB_HEX := Vector2i(0, 0)
## 上を歩けるピース
const WALKABLE_PIECES := [PieceData.Type.CONVEYOR, PieceData.Type.BRIDGE]

var chunk_hex: Vector2i
var hex: Vector2i


func _init(p_chunk_hex: Vector2i, p_hex: Vector2i) -> void:
	chunk_hex = p_chunk_hex
	hex = p_hex


## 押している方向 input（画面の向き。y は下が正）に歩くときの、隣のマスへの方向（0〜5）。
## 押していなければ -1。上下だけのように2方向がちょうど同じだけ近いときは、
## 前回の方向 last_direction でない方を選び、交互に進んでまっすぐ歩けるようにする。
static func direction_for_input(input: Vector2, last_direction: int) -> int:
	if input == Vector2.ZERO:
		return -1
	var wanted := input.normalized()
	var layout := Layout.make_default()
	var best_score := -INF
	var tied: Array[int] = []
	for i in range(Hex.DIRECTIONS.size()):
		var score := wanted.dot(Layout.hex_to_pixel(layout, Hex.direction(i)).normalized())
		if score > best_score + 0.0001:
			best_score = score
			tied = [i]
		elif score > best_score - 0.0001:
			tied.append(i)
	if tied.size() > 1 and tied[0] == last_direction:
		return tied[1]
	return tied[0]


## chunk の hex のマスに入れるか。chunk の中で、何も無いか、上を歩けるコンベアや橋のマスだけ。
## 鉱床は通れる。
static func can_enter(chunk: Chunk, target: Vector2i) -> bool:
	if not chunk.is_inside_grid(target):
		return false
	var piece := chunk.get_piece_at_hex(target)
	return piece == null or piece.piece_type in WALKABLE_PIECES


## chunk で最初に立つマス。ハブの隣のうち、施設の置かれていない最初のマス。
## すべてふさがっていればハブの東隣。
static func spawn_hex(chunk: Chunk) -> Vector2i:
	for candidate in Hex.neighbors(HUB_HEX):
		if chunk.is_inside_grid(candidate) and not chunk.is_occupied(candidate):
			return candidate
	return Hex.neighbor(HUB_HEX, 0)
