extends RefCounted
## 見た目確認用。キャラクターの足元に Smelter を置いて押し出したあと、同じマスをもう一度クリックし、
## カーソルの近くに出る理由と赤いゴーストを映す

const Feedback = preload("res://tools/scenarios/placement_feedback.gd")


func run(scene: Node) -> void:
	var feedback = Feedback.new()
	var world: World = scene.world
	var chunk: Chunk = world.get_active_chunk()
	HubGoals.creative_mode = true
	world.place_player(world.get_active_hex(), Feedback.PLAYER_HEX)
	await scene.get_tree().process_frame
	scene.hud.select_slot(2)
	await feedback._click(scene, chunk, Feedback.PLAYER_HEX)
	await feedback._click(scene, chunk, Feedback.PLAYER_HEX)
	await scene.get_tree().process_frame
