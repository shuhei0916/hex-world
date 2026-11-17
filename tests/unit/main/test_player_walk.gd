extends GutTest

## ローカル画面では WASD でキャラクターが1マスずつ歩き、カメラがキャラクターを追う。
## 押し続けると一定の間隔で歩き続ける。WASD でカメラは動かない（ワールドマップでは動く）。

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


func test_右を押すと東へ1歩歩く():
	main.update_walk(RIGHT, 0.016)
	assert_eq(_player_hex(), Vector2i(2, 0))


func test_押し続けても一定の間隔を空けて歩く():
	main.update_walk(RIGHT, 0.016)
	main.update_walk(RIGHT, 0.016)
	assert_eq(_player_hex(), Vector2i(2, 0), "間隔が空くまでは次の1歩を踏まない")
	main.update_walk(RIGHT, Main.STEP_INTERVAL)
	assert_eq(_player_hex(), Vector2i(3, 0))


func test_離して押し直すとすぐに歩く():
	main.update_walk(RIGHT, 0.016)
	main.update_walk(Vector2.ZERO, 0.016)
	main.update_walk(RIGHT, 0.016)
	assert_eq(_player_hex(), Vector2i(3, 0))


func test_カメラがキャラクターを追う():
	main.update_walk(RIGHT, 0.016)
	await wait_seconds(0.3)
	assert_true(main.camera.position.is_equal_approx(main.world.get_player_position()))


func test_ワールドマップでは歩かない():
	main._toggle_mode()
	main.update_walk(RIGHT, 0.016)
	assert_eq(_player_hex(), Vector2i(1, 0))


func test_研究画面を開いている間は歩かない():
	main.hud.toggle_research_panel()
	main.update_walk(RIGHT, 0.016)
	assert_eq(_player_hex(), Vector2i(1, 0))


func test_戦闘中は歩かない():
	main.start_battle(Vector2i(1, 0))
	main.update_walk(RIGHT, 0.016)
	assert_eq(_player_hex(), Vector2i(1, 0))


func test_ローカル画面ではWASDでカメラを動かさない():
	assert_false(main.camera.keyboard_move_enabled)


func test_ワールドマップではWASDでカメラを動かす():
	main._toggle_mode()
	assert_true(main.camera.keyboard_move_enabled)


func test_戦闘中はWASDでカメラを動かす():
	main.start_battle(Vector2i(1, 0))
	assert_true(main.camera.keyboard_move_enabled)


func test_上だけを押して片方の斜めがふさがっていれば_もう片方の斜めへ歩く():
	# 東の端では北東が chunk の外なので、北西へ歩いて端に沿って上へ進む
	var radius = main.world.get_active_chunk().grid_radius
	main.world.place_player(Vector2i(0, 0), Vector2i(radius, -1))
	main.update_walk(Vector2(0, -1), 0.016)
	assert_eq(_player_hex(), Vector2i(radius, -2))


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
