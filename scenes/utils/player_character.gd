class_name PlayerCharacter
extends RefCounted
## プレイヤーキャラクター。どの chunk の、どのマスに立っているかを持つ。
## 戦闘の主人公と同じ1人で、ふだんは工場のある世界を歩く。

## ハブの位置。新しいゲームではこの隣に現れる
const HUB_HEX := Vector2i(0, 0)

var chunk_hex: Vector2i
var hex: Vector2i


func _init(p_chunk_hex: Vector2i, p_hex: Vector2i) -> void:
	chunk_hex = p_chunk_hex
	hex = p_hex


## chunk で最初に立つマス。ハブの隣のうち、施設の置かれていない最初のマス。
## すべてふさがっていればハブの東隣。
static func spawn_hex(chunk: Chunk) -> Vector2i:
	for candidate in Hex.neighbors(HUB_HEX):
		if chunk.is_inside_grid(candidate) and not chunk.is_occupied(candidate):
			return candidate
	return Hex.neighbor(HUB_HEX, 0)
