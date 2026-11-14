extends RefCounted

## 隣接 chunk と橋の確認。原点 chunk の東の辺に橋、その先の chunk の向かいのマスに
## 受け取るコンベアを置き、画面上の距離・つながったか・溝の上の帯・アイテムが渡るか・
## ホバー情報を出力する。

const BRIDGE = preload("res://scenes/components/piece/bridge.tscn")
const CONVEYOR = preload("res://scenes/components/piece/conveyor.tscn")


func run(scene: Node) -> void:
	HubGoals.creative_mode = true
	var world: World = scene.world
	var origin = world.get_active_chunk()
	print("隣の chunk: ", world.get_neighbor_hexes())
	var bridge_hex = Hex.new(5, -2)
	var edge_dir = origin.get_edge_direction(bridge_hex)
	var target_chunk_hex = Hex.neighbor(Hex.new(0, 0), ChunkTopology.to_world_direction(edge_dir))
	var target = world.get_chunk(target_chunk_hex)
	var landing_hex = ChunkTopology.mirror_hex(bridge_hex, edge_dir)
	origin.place_piece(BRIDGE, bridge_hex, 0)
	print("置く前の着地点の光: ", target.find_hex_tile(landing_hex).is_highlighted)
	target.place_piece(CONVEYOR, landing_hex, 0)

	var bridge_pos = origin.position + origin.hex_to_pixel(bridge_hex)
	var landing_pos = target.position + target.hex_to_pixel(landing_hex)
	print("橋 %s 画面位置 %s" % [bridge_hex, bridge_pos])
	print("着地点 %s (chunk %s) 画面位置 %s" % [landing_hex, target_chunk_hex, landing_pos])
	print("距離 %.1f（溝 %d 段）" % [bridge_pos.distance_to(landing_pos), World.gap_steps])
	var bridge = origin.get_piece_at_hex(bridge_hex)
	print("接続: ", bridge.has_connected_piece())
	print("溝の上の帯: ", world.get_bridge_spans())

	bridge.add_item("iron_ore", 1)
	for i in 120:
		await scene.get_tree().process_frame
	print("しばらく後、向かいのコンベアに届いた: ", target.get_piece_at_hex(landing_hex).get_node("ConveyorLogic").get_held_item())

	scene._hover_local(landing_pos)
	await scene.get_tree().process_frame
	print("隣のコンベアにホバー → 情報: ", scene.hud.info_panel.name_label.text)
	print("隣の chunk の中には置けない: ", not scene.piece_placer.place_piece_at_hex(Hex.new(-2, 8)))
