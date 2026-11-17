extends GutTest

## プレイヤーキャラクターは、どの chunk の、どのマスに立っているかを持つ。
## 新しいゲームでは、ハブのすぐ隣の空いているマスに現れる。

const HUB = preload("res://scenes/components/piece/hub.tscn")
const CONVEYOR = preload("res://scenes/components/piece/conveyor.tscn")

var chunk: Chunk


func before_each():
	chunk = Chunk.new()
	add_child_autofree(chunk)
	chunk.place_piece(HUB, Vector2i(0, 0))


func test_立っている場所を持つ():
	var player := PlayerCharacter.new(Vector2i(1, 0), Vector2i(2, -1))
	assert_eq(player.chunk_hex, Vector2i(1, 0))
	assert_eq(player.hex, Vector2i(2, -1))


func test_最初に立つマスはハブの隣():
	var hex := PlayerCharacter.spawn_hex(chunk)
	assert_eq(Hex.distance(hex, Vector2i(0, 0)), 1)


func test_ハブの隣が施設でふさがっていれば空いているマスに立つ():
	var first := PlayerCharacter.spawn_hex(chunk)
	chunk.place_piece(CONVEYOR, first)
	var hex := PlayerCharacter.spawn_hex(chunk)
	assert_ne(hex, first)
	assert_eq(Hex.distance(hex, Vector2i(0, 0)), 1)
