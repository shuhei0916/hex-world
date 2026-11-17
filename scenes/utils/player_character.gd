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
## 鉱床は通れる。
static func can_enter(chunk: Chunk, target: Vector2i) -> bool:
	if not chunk.is_inside_grid(target):
		return false
	var piece := chunk.get_piece_at_hex(target)
	return piece == null or piece.piece_type in WALKABLE_PIECES


## chunk の中の位置 pos に立てるか。体の中心と縁が、すべて入れるマスの上にあるときだけ。
static func can_stand_at(chunk: Chunk, pos: Vector2) -> bool:
	if not can_enter(chunk, Layout.pixel_to_hex_rounded(chunk.layout, pos)):
		return false
	for i in range(BODY_SAMPLES):
		var edge := pos + Vector2.from_angle(TAU * i / BODY_SAMPLES) * BODY_RADIUS
		if not can_enter(chunk, Layout.pixel_to_hex_rounded(chunk.layout, edge)):
			return false
	return true


## chunk で最初に立つマス。ハブの隣のうち、施設の置かれていない最初のマス。
## すべてふさがっていればハブの東隣。
static func spawn_hex(chunk: Chunk) -> Vector2i:
	for candidate in Hex.neighbors(HUB_HEX):
		if chunk.is_inside_grid(candidate) and not chunk.is_occupied(candidate):
			return candidate
	return Hex.neighbor(HUB_HEX, 0)
