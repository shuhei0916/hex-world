extends GutTest

## プレイヤーキャラクターは、どの chunk の、どのマスに立っているかを持つ。
## 新しいゲームでは、ハブのすぐ隣の空いているマスに現れる。

const HUB = preload("res://scenes/components/piece/hub.tscn")
const CONVEYOR = preload("res://scenes/components/piece/conveyor.tscn")
const SMELTER = preload("res://scenes/components/piece/smelter_t1.tscn")

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


# ---- 歩く方向 ----------------------------------------------------------------
# マスは頂点が上を向いているので、真横には東・西があり、上下には真上・真下が無い。
# 上下だけを押したときは、北東と北西（南東と南西）を交互に選んでまっすぐ進む。


func test_右なら東():
	assert_eq(PlayerCharacter.direction_for_input(Vector2(1, 0), -1), 0)


func test_左なら西():
	assert_eq(PlayerCharacter.direction_for_input(Vector2(-1, 0), -1), 3)


func test_右上なら北東_左上なら北西():
	assert_eq(PlayerCharacter.direction_for_input(Vector2(1, -1), -1), 1)
	assert_eq(PlayerCharacter.direction_for_input(Vector2(-1, -1), -1), 2)


func test_右下なら南東_左下なら南西():
	assert_eq(PlayerCharacter.direction_for_input(Vector2(1, 1), -1), 5)
	assert_eq(PlayerCharacter.direction_for_input(Vector2(-1, 1), -1), 4)


func test_上だけなら北東と北西を交互に選ぶ():
	var first := PlayerCharacter.direction_for_input(Vector2(0, -1), -1)
	assert_true(first in [1, 2])
	var second := PlayerCharacter.direction_for_input(Vector2(0, -1), first)
	assert_true(second in [1, 2])
	assert_ne(second, first)


func test_下だけなら南東と南西を交互に選ぶ():
	assert_eq(PlayerCharacter.direction_for_input(Vector2(0, 1), 4), 5)
	assert_eq(PlayerCharacter.direction_for_input(Vector2(0, 1), 5), 4)


func test_何も押していなければ歩かない():
	assert_eq(PlayerCharacter.direction_for_input(Vector2.ZERO, 0), -1)


# ---- 通れるマス --------------------------------------------------------------


func test_何も無いマスは通れる():
	assert_true(PlayerCharacter.can_enter(chunk, Vector2i(2, 0)))


func test_鉱床は通れる():
	chunk.mark_resource_hex(Vector2i(2, 0), "iron_ore")
	assert_true(PlayerCharacter.can_enter(chunk, Vector2i(2, 0)))


func test_コンベアの上は通れる():
	chunk.place_piece(CONVEYOR, Vector2i(2, 0))
	assert_true(PlayerCharacter.can_enter(chunk, Vector2i(2, 0)))


func test_機械やハブは通れない():
	chunk.place_piece(SMELTER, Vector2i(2, 0))
	assert_false(PlayerCharacter.can_enter(chunk, Vector2i(2, 0)))
	assert_false(PlayerCharacter.can_enter(chunk, Vector2i(0, 0)))


func test_chunkの外へは出られない():
	assert_false(PlayerCharacter.can_enter(chunk, Vector2i(chunk.grid_radius + 1, 0)))
