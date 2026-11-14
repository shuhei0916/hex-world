extends RefCounted

## ローカル画面とワールドマップの切り替わりの見比べ用（screenshot.sh と組み合わせる）。
## 環境変数 ZOOM の倍率まで引く。Main.LOCAL_TO_MAP_ZOOM の少し上と少し下で撮って見比べる。

const LAYOUT = preload("res://tools/scenarios/visual_layout.gd")


func run(scene: Node) -> void:
	await LAYOUT.new().run(scene)
	scene.camera.position = Vector2(150, 80)
	scene.camera.zoom = Vector2.ONE * float(OS.get_environment("ZOOM"))
	for i in 5:
		await scene.get_tree().process_frame
	print("倍率 %.3f / %s" % [scene.camera.zoom.x, "ローカル" if scene.is_local_mode() else "ワールドマップ"])
