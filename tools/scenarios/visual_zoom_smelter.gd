extends RefCounted

## visual_layout.gd の配置で、Smelter の周りを拡大する（screenshot.sh と組み合わせる）

const LAYOUT = preload("res://tools/scenarios/visual_layout.gd")


func run(scene: Node) -> void:
	await LAYOUT.new().run(scene)
	var chunk: Chunk = scene.world.get_active_chunk()
	scene.camera.position = chunk.hex_to_pixel(Hex.new(-2, 3))
	scene.camera.zoom = Vector2(2.2, 2.2)
	for i in 5:
		await scene.get_tree().process_frame
