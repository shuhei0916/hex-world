extends RefCounted

## カメラのかくつきの調査用。起動直後と、戦闘に勝って／撤退して建築に戻った前後の各フレームで、
## カメラの位置・倍率・実際に映している中心と、キャラクターの画面上の位置を出力する。


func run(scene: Node) -> void:
	var tree = scene.get_tree()
	print("--- 起動直後 ---")
	for i in range(6):
		_dump(scene, "start %d" % i)
		await tree.process_frame
	print("--- 東へ渡って戦い、勝つ ---")
	scene.world.place_player(Vector2i(0, 0), Vector2i(2, Chunk.DEFAULT_RADIUS - 2))
	scene.try_cross()
	for i in range(3):
		_dump(scene, "battle %d" % i)
		await tree.process_frame
	var battle_scene: BattleScene = scene.battle_overlay.battle_scene
	for enemy in battle_scene.battle.enemies():
		battle_scene.battle.field.remove_unit(enemy)
	battle_scene.refresh()
	await tree.process_frame
	scene.battle_overlay.confirm_result()
	for i in range(12):
		_dump(scene, "after win %d" % i)
		await tree.process_frame
	print("--- 次へ渡って撤退 ---")
	scene.world.place_player(Vector2i(1, 0), Vector2i(2, Chunk.DEFAULT_RADIUS - 2))
	scene.try_cross()
	await tree.process_frame
	scene.battle_overlay.retreat()
	for i in range(12):
		_dump(scene, "after retreat %d" % i)
		await tree.process_frame


func _dump(scene: Node, label: String) -> void:
	var camera: Camera2D = scene.camera
	var view: Node2D = scene.world.get_node("PlayerView")
	print(
		(
			"[%s] cam=%s screen_center=%s zoom=%.3f player_view=%s visible=%s"
			% [
				label,
				camera.position.round(),
				camera.get_screen_center_position().round(),
				camera.zoom.x,
				view.global_position.round(),
				view.visible,
			]
		)
	)
