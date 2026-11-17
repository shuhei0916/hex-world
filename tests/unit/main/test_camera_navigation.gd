extends GutTest

## 今いる chunk はキャラクターの立っている chunk で、カメラを動かしても変わらない。
## 一定より引くとワールドマップへ、ワールドマップで寄せるとローカル画面へ、見え方を保ったまま移る。

const MainScene = preload("res://scenes/main/main.tscn")
const SAVE_PATH := "user://test_camera_navigation_save.json"

var main: Main


func before_each():
	SaveGame.path = SAVE_PATH
	SaveGame.delete()
	HubGoals.reset()
	main = MainScene.instantiate()
	add_child_autofree(main)
	# 東隣は解放済みとして、所有している chunk どうしの行き来を確かめる
	main.world.territory.claim(Vector2i(1, 0))


func after_each():
	await get_tree().process_frame
	SaveGame.delete()
	SaveGame.path = SaveGame.DEFAULT_PATH
	HubGoals.reset()


func _east() -> Chunk:
	return main.world.get_chunk(Vector2i(1, 0))


func test_カメラを隣のchunkの方へ動かしても今いるchunkは変わらない():
	# 今いる chunk はキャラクターの立っている chunk で決まる
	main.camera.position = _east().position * 0.6
	main.update_navigation()
	assert_true(main.world.get_active_hex() == Vector2i(0, 0))


func test_一定より引くとワールドマップに切り替わる():
	main.camera.zoom = Vector2.ONE * (Main.LOCAL_TO_MAP_ZOOM - 0.01)
	main.update_navigation()
	assert_false(main.is_local_mode())


func test_ワールドマップへは見え方を保ったまま移る():
	var east_position = _east().position
	main.camera.position = east_position * 0.3
	var local_zoom = Main.LOCAL_TO_MAP_ZOOM - 0.01
	main.camera.zoom = Vector2.ONE * local_zoom
	main.update_navigation()
	var view = main.world_map_view
	var scale = view.get_tile_spacing() / main.world.get_chunk_spacing()
	var east_tile = view.to_global(view.get_tile_position(Vector2i(1, 0)))
	var origin_tile = view.to_global(view.get_tile_position(Vector2i(0, 0)))
	assert_true(main.camera.position.is_equal_approx(origin_tile.lerp(east_tile, 0.3)))
	assert_almost_eq(main.camera.zoom.x, local_zoom / scale, 0.0001)


func test_引いていなければワールドマップに切り替わらない():
	main.camera.zoom = Vector2.ONE * (Main.LOCAL_TO_MAP_ZOOM + 0.1)
	main.update_navigation()
	assert_true(main.is_local_mode())


func test_ワールドマップで寄せるとキャラクターのいるchunkのローカル画面に入る():
	main._toggle_mode()
	var view = main.world_map_view
	var scale = view.get_tile_spacing() / main.world.get_chunk_spacing()
	var east_tile = view.to_global(view.get_tile_position(Vector2i(1, 0)))
	main.camera.position = east_tile
	main.camera.zoom = Vector2.ONE * (Main.MAP_TO_LOCAL_ZOOM + 0.01) / scale
	main.update_navigation()
	assert_true(main.is_local_mode())
	assert_true(main.world.get_active_hex() == Vector2i(0, 0))
	assert_true(main.camera.position.is_equal_approx(main.world.get_player_position()))
	assert_almost_eq(main.camera.zoom.x, Main.MAP_TO_LOCAL_ZOOM + 0.01, 0.0001)


func test_スペースで開いたワールドマップはすぐにはローカルへ戻らない():
	main._toggle_mode()
	main.update_navigation()
	assert_false(main.is_local_mode())


func test_ローカルへ入る倍率は出る倍率より大きく_行き来がちらつかない():
	assert_gt(Main.MAP_TO_LOCAL_ZOOM, Main.LOCAL_TO_MAP_ZOOM)
