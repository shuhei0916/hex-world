extends GutTest

## パンで隣の chunk に移ると、その chunk が「今いる chunk」になる。
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


func after_each():
	await get_tree().process_frame
	SaveGame.delete()
	SaveGame.path = SaveGame.DEFAULT_PATH
	HubGoals.reset()


func _east() -> Chunk:
	return main.world.get_chunk(Hex.new(1, 0))


func test_カメラの中心が隣のchunkの方に近づくとそのchunkが今いるchunkになる():
	var east_position = _east().position
	main.camera.position = east_position * 0.6
	main.update_navigation()
	assert_true(Hex.equals(main.world.get_active_hex(), Hex.new(1, 0)))
	assert_eq(main.piece_placer.chunk, _east(), "設置先もその chunk になる")


func test_切り替えても画面の見え方は変わらない():
	var east_position = _east().position
	main.camera.position = east_position * 0.6
	main.update_navigation()
	# 新しく今いる chunk は原点に来るので、カメラも同じだけずらす
	assert_true(main.camera.position.is_equal_approx(east_position * 0.6 - east_position))


func test_今いるchunkの中心の方が近いうちは切り替えない():
	main.camera.position = _east().position * 0.4
	main.update_navigation()
	assert_true(Hex.equals(main.world.get_active_hex(), Hex.new(0, 0)))


func test_設置のドラッグ中は切り替えない():
	main.piece_placer.start_drag()
	main.camera.position = _east().position * 0.6
	main.update_navigation()
	assert_true(Hex.equals(main.world.get_active_hex(), Hex.new(0, 0)))
	main.piece_placer.stop_drag()


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
	var east_tile = view.to_global(view.get_tile_position(Hex.new(1, 0)))
	var origin_tile = view.to_global(view.get_tile_position(Hex.new(0, 0)))
	assert_true(main.camera.position.is_equal_approx(origin_tile.lerp(east_tile, 0.3)))
	assert_almost_eq(main.camera.zoom.x, local_zoom / scale, 0.0001)


func test_引いていなければワールドマップに切り替わらない():
	main.camera.zoom = Vector2.ONE * (Main.LOCAL_TO_MAP_ZOOM + 0.1)
	main.update_navigation()
	assert_true(main.is_local_mode())


func test_ワールドマップで寄せると画面中央のchunkのローカル画面に入る():
	main._toggle_mode()
	var view = main.world_map_view
	var scale = view.get_tile_spacing() / main.world.get_chunk_spacing()
	var east_tile = view.to_global(view.get_tile_position(Hex.new(1, 0)))
	main.camera.position = east_tile
	main.camera.zoom = Vector2.ONE * (Main.MAP_TO_LOCAL_ZOOM + 0.01) / scale
	main.update_navigation()
	assert_true(main.is_local_mode())
	assert_true(Hex.equals(main.world.get_active_hex(), Hex.new(1, 0)))
	assert_true(main.camera.position.is_equal_approx(Vector2.ZERO))
	assert_almost_eq(main.camera.zoom.x, Main.MAP_TO_LOCAL_ZOOM + 0.01, 0.0001)


func test_スペースで開いたワールドマップはすぐにはローカルへ戻らない():
	main._toggle_mode()
	main.update_navigation()
	assert_false(main.is_local_mode())


func test_ローカルへ入る倍率は出る倍率より大きく_行き来がちらつかない():
	assert_gt(Main.MAP_TO_LOCAL_ZOOM, Main.LOCAL_TO_MAP_ZOOM)
