extends RefCounted

## 見た目確認用。コンベアのつなぎ目（直線どうし・直線と曲がり）を大きく拡大して映す。
## 環境変数 SEAM_ZOOM で倍率を変えられる（既定 5）

const CONVEYOR = preload("res://scenes/components/piece/conveyor.tscn")


func run(scene: Node) -> void:
	HubGoals.creative_mode = true
	var chunk: Chunk = scene.world.get_active_chunk()
	# 西から東へ直線で3マス、その先で曲がる1マス（両端は行き止まり）
	chunk.place_piece(CONVEYOR, Vector2i(-4, 3), 0)
	chunk.place_piece(CONVEYOR, Vector2i(-3, 3), 0)
	chunk.place_piece(CONVEYOR, Vector2i(-2, 3), 0)
	chunk.place_piece(CONVEYOR, Vector2i(-1, 3), 1)
	var zoom = float(OS.get_environment("SEAM_ZOOM")) if OS.has_environment("SEAM_ZOOM") else 5.0
	scene.camera.position = chunk.hex_to_pixel(Vector2i(-2, 3)) + Vector2(-20, 0)
	scene.camera.zoom = Vector2(zoom, zoom)
	for i in 10:
		await scene.get_tree().process_frame
