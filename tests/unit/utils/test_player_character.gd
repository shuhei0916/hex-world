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


# ---- 位置 ------------------------------------------------------------------
# キャラクターはマスに縛られず、chunk の中の位置（ピクセル）に立つ。立っているマスはそこから決まる。


func _center(hex: Vector2i) -> Vector2:
	return Layout.hex_to_pixel(Layout.make_default(), hex)


func test_マスを指定して立たせるとそのマスの中心にいる():
	var player := PlayerCharacter.new(Vector2i(0, 0), Vector2i(2, -1))
	assert_eq(player.position, _center(Vector2i(2, -1)))


func test_少し動いても立っているマスは変わらない():
	var player := PlayerCharacter.new(Vector2i(0, 0), Vector2i(2, -1))
	player.position += Vector2(10, 5)
	assert_eq(player.hex, Vector2i(2, -1))


func test_隣のマスの方が近くなると立っているマスが変わる():
	var player := PlayerCharacter.new(Vector2i(0, 0), Vector2i(2, 0))
	player.position = _center(Vector2i(2, 0)).lerp(_center(Vector2i(3, 0)), 0.6)
	assert_eq(player.hex, Vector2i(3, 0))


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


# ---- 立てる位置 --------------------------------------------------------------
# 体には大きさがあるので、体のどこかが通れないマスや chunk の外にかかる位置には立てない。


func test_何も無いマスの中には立てる():
	assert_true(PlayerCharacter.can_stand_at(chunk, _center(Vector2i(2, 0))))


func test_機械のマスの中には立てない():
	chunk.place_piece(SMELTER, Vector2i(2, 0))
	assert_false(PlayerCharacter.can_stand_at(chunk, _center(Vector2i(2, 0))))


func test_体の端が機械のマスにかかる位置には立てない():
	chunk.place_piece(SMELTER, Vector2i(3, 0))
	var near_edge = _center(Vector2i(2, 0)).lerp(_center(Vector2i(3, 0)), 0.45)
	assert_false(PlayerCharacter.can_stand_at(chunk, near_edge))


func test_chunkの外にはみ出す位置には立てない():
	var edge = Vector2i(chunk.grid_radius, 0)
	var outside = _center(edge) + Vector2(PlayerCharacter.BODY_RADIUS * 2.0, 0)
	assert_false(PlayerCharacter.can_stand_at(chunk, outside))
