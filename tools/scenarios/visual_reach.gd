extends RefCounted

## 見た目確認用。Smelter を選び、キャラクターから届かないマスにカーソルを合わせる（ゴーストが赤くなる）。
## 環境変数 REACH_VIEW=near なら届くマスに合わせる。

const SMELTER_SLOT := 1


func run(scene: Node) -> void:
	HubGoals.toggle_creative_mode()
	scene.hud.select_slot(SMELTER_SLOT)
	await scene.get_tree().process_frame
	var player_hex: Vector2i = scene.world.player.hex
	var target = player_hex + Vector2i(-2, 1)
	if OS.get_environment("REACH_VIEW") != "near":
		target = player_hex + Vector2i(-5, 1)
	var chunk: Chunk = scene.world.get_active_chunk()
	var screen = scene.get_viewport().get_canvas_transform() * chunk.hex_to_pixel(target)
	var motion := InputEventMouseMotion.new()
	motion.position = screen
	motion.global_position = screen
	Input.parse_input_event(motion)
	await scene.get_tree().process_frame
	print("target=%s tint=%s" % [target, scene.piece_placer.snap_preview.modulate])
