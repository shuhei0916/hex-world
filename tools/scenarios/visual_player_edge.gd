extends RefCounted

## 見た目確認用。キャラクターを東隣（所有していない）に面した辺に立たせ、渡るキーの案内を出す。


func run(scene: Node) -> void:
	scene.world.place_player(Vector2i(0, 0), Vector2i(2, 3))
	scene.camera.position = scene.world.get_player_position()
	await scene.get_tree().process_frame
