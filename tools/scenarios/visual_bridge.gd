extends RefCounted

## 橋の見た目の確認用（screenshot.sh と組み合わせる）。原点 chunk の東の辺に、
## 受け取り先のある橋（アイテムを流し続ける）と、受け取り先の無い橋を並べて拡大する。

const BRIDGE = preload("res://scenes/components/piece/bridge.tscn")
const CONVEYOR = preload("res://scenes/components/piece/conveyor.tscn")


func run(scene: Node) -> void:
	HubGoals.creative_mode = true
	var world: World = scene.world
	var origin: Chunk = world.get_active_chunk()
	var connected_hex = Hex.new(5, -2)
	var open_hex = Hex.new(5, -4)
	var edge_dir = origin.get_edge_direction(connected_hex)
	var target: Chunk = world.get_chunk(
		Hex.neighbor(Hex.new(0, 0), ChunkTopology.to_world_direction(edge_dir))
	)
	origin.place_piece(BRIDGE, connected_hex, 0)
	origin.place_piece(BRIDGE, open_hex, 0)
	# 橋へ流し込むコンベアと、向こう側で受け取って奥へ運ぶコンベア
	origin.place_piece(CONVEYOR, Hex.new(4, -2), 0)
	var landing = ChunkTopology.mirror_hex(connected_hex, edge_dir)
	target.place_piece(CONVEYOR, landing, 0)
	target.place_piece(CONVEYOR, Hex.add(landing, Hex.direction(0)), 0)
	var bridge = origin.get_piece_at_hex(connected_hex)
	var mid = (
		origin.hex_to_pixel(Hex.new(5, -3))
		+ target.position
		+ target.hex_to_pixel(ChunkTopology.mirror_hex(Hex.new(5, -3), edge_dir))
	) * 0.5
	scene.camera.position = mid
	scene.camera.zoom = Vector2(1.6, 1.6)
	for i in 90:
		if bridge.get_node("ConveyorLogic").get_held_item() == "":
			bridge.add_item("iron_ore", 1)
		await scene.get_tree().process_frame
