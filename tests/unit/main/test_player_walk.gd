extends GutTest

## ローカル画面では WASD でキャラクターがマスに縛られず自由に歩き、カメラがキャラクターを追う。
## WASD でカメラは動かない（ワールドマップと戦闘中は動く。戦闘ではマス単位で動く）。

const MainScene = preload("res://scenes/main/main.tscn")
const SAVE_PATH := "user://test_player_walk_save.json"
const RIGHT := Vector2(1, 0)
# 東隣 (1, 0) の chunk に面した辺（SE）の、角でないマス
const EAST_EDGE_HEX := Vector2i(2, 3)

var main: Main


func before_each():
	SaveGame.path = SAVE_PATH
	SaveGame.delete()
	HubGoals.reset()
	main = MainScene.instantiate()
	add_child_autofree(main)
	# ハブの東隣から東へ歩く（鉱床は通れるので、東の道には何も無い）
	main.world.place_player(Vector2i(0, 0), Vector2i(1, 0))


func after_each():
	await get_tree().process_frame
	SaveGame.delete()
	SaveGame.path = SaveGame.DEFAULT_PATH
	HubGoals.reset()


func _player_hex() -> Vector2i:
	return main.world.player.hex


func _player_position() -> Vector2:
	return main.world.player.position


func test_押している間_その向きへ一定の速さでなめらかに動く():
	var start = _player_position()
	main.update_walk(RIGHT, 0.1)
	assert_almost_eq(_player_position().x - start.x, Main.WALK_SPEED * 0.1, 0.001)
	assert_eq(_player_position().y, start.y)


func test_斜めに押しても速さは変わらない():
	var start = _player_position()
	main.update_walk(Vector2(1, 1), 0.1)
	assert_almost_eq(_player_position().distance_to(start), Main.WALK_SPEED * 0.1, 0.001)


func test_マスの境目を越えるまでは立っているマスは変わらない():
	main.update_walk(RIGHT, 0.05)
	assert_eq(_player_hex(), Vector2i(1, 0))
	main.update_walk(RIGHT, 0.3)
	assert_eq(_player_hex(), Vector2i(2, 0))


func test_カメラは歩いている間キャラクターを追う():
	main.update_walk(RIGHT, 0.1)
	assert_true(main.camera.position.is_equal_approx(main.world.get_player_position()))


func test_ワールドマップでは歩かない():
	main._toggle_mode()
	var start = _player_position()
	main.update_walk(RIGHT, 0.1)
	assert_eq(_player_position(), start)


func test_研究画面を開いている間は歩かない():
	main.hud.toggle_research_panel()
	var start = _player_position()
	main.update_walk(RIGHT, 0.1)
	assert_eq(_player_position(), start)


func test_戦闘中は歩かない():
	main.start_battle(Vector2i(1, 0))
	var start = _player_position()
	main.update_walk(RIGHT, 0.1)
	assert_eq(_player_position(), start)


func test_ローカル画面ではWASDでカメラを動かさない():
	assert_false(main.camera.keyboard_move_enabled)


func test_ワールドマップではWASDでカメラを動かす():
	main._toggle_mode()
	assert_true(main.camera.keyboard_move_enabled)


func test_戦闘中はWASDでカメラを動かす():
	main.start_battle(Vector2i(1, 0))
	assert_true(main.camera.keyboard_move_enabled)


# ---- 渡れる場所の案内 ----
# chunk の辺に立つと、キャラクターの上に渡るキーの案内を出す。


func _prompt_label() -> Label:
	return main.world.get_node("PlayerView/Prompt")


func test_所有している隣に面した辺では渡る案内を出す():
	main.world.territory.claim(Vector2i(1, 0))
	main.world.place_player(Vector2i(0, 0), EAST_EDGE_HEX)
	assert_eq(main.crossing_prompt(), "[F] 渡る")


func test_所有していない隣に面した辺では戦って解放する案内を出す():
	main.world.place_player(Vector2i(0, 0), EAST_EDGE_HEX)
	assert_eq(main.crossing_prompt(), "[F] 戦って解放")


func test_内側のマスでは案内を出さない():
	assert_eq(main.crossing_prompt(), "")


func test_案内はキャラクターの上に表示される():
	main.world.place_player(Vector2i(0, 0), EAST_EDGE_HEX)
	main._process(0.0)
	assert_true(_prompt_label().visible)
	assert_eq(_prompt_label().text, "[F] 戦って解放")
	main.world.place_player(Vector2i(0, 0), Vector2i(1, 0))
	main._process(0.0)
	assert_false(_prompt_label().visible)


# ---- 建築できる範囲 ----


func test_建築はキャラクターの近くだけ():
	main._process(0.0)
	assert_eq(main.piece_placer.reach_center, Vector2i(1, 0))


func test_歩くと建築できる範囲もついてくる():
	main.update_walk(RIGHT, 0.4)
	main._process(0.0)
	assert_eq(main.piece_placer.reach_center, Vector2i(2, 0))
