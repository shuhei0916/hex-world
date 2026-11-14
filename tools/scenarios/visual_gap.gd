extends RefCounted

## 溝の幅の見比べ用（screenshot.sh と組み合わせる）。環境変数 GAP_STEPS で World.gap_steps を変え、
## visual_layout.gd の配置を引いて映す。例: GAP_STEPS=3 screenshot.sh "--do=script:...;shot:..."

const LAYOUT = preload("res://tools/scenarios/visual_layout.gd")
const ZOOM := 0.42


func run(scene: Node) -> void:
	var steps = OS.get_environment("GAP_STEPS")
	if steps != "":
		World.gap_steps = int(steps)
	await LAYOUT.new().run(scene)
	scene.world.set_active_chunk(scene.world.get_active_hex())
	scene.camera.position = Vector2.ZERO
	scene.camera.zoom = Vector2(ZOOM, ZOOM)
	print("溝: ", World.gap_steps, " 段")
	for i in 5:
		await scene.get_tree().process_frame
