extends RefCounted

## カメラによる移動の確認。東へ少しずつパンして今いる chunk が切り替わる様子と、
## ホイールで引いてワールドマップへ、寄せてローカル画面へ戻る様子を出力する。


func run(scene: Node) -> void:
	var world: World = scene.world
	var camera: CameraController = scene.camera
	var tree = scene.get_tree()
	var east = world.get_chunk(Hex.new(1, 0)).position
	print("東の chunk の位置: ", east)
	for i in 8:
		camera.position += east * 0.25
		await tree.process_frame
		print(
			"パン %d: カメラ %s → 今いる chunk %s" % [i + 1, camera.position.round(), world.get_active_hex()]
		)
	print("--- ホイールで引く ---")
	for i in 12:
		camera.change_zoom(-camera.zoom_sensitivity)
		await tree.process_frame
		print(
			(
				"倍率 %.2f / %s / 今いる chunk %s"
				% [camera.zoom.x, "ローカル" if scene.is_local_mode() else "ワールドマップ", world.get_active_hex()]
			)
		)
		if not scene.is_local_mode():
			break
	print("--- ワールドマップで寄せる ---")
	for i in 30:
		camera.change_zoom(camera.zoom_sensitivity)
		await tree.process_frame
		if scene.is_local_mode():
			print("倍率 %.2f でローカルへ: 今いる chunk %s カメラ %s" % [camera.zoom.x, world.get_active_hex(), camera.position.round()])
			break
