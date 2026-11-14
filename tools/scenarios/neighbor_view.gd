extends RefCounted

## 隣接 chunk の描画の確認。原点 chunk の東の辺に Sender、その先の chunk の対応位置に
## Receiver を置き、画面上の位置が隣り合う（距離 ≒ マス1つ分）かと、ホバー情報を出力する。

const SENDER = preload("res://scenes/components/piece/sender.tscn")
const RECEIVER = preload("res://scenes/components/piece/receiver.tscn")


func run(scene: Node) -> void:
	HubGoals.creative_mode = true
	var world: World = scene.world
	var origin = world.get_active_chunk()
	print("隣の chunk: ", world.get_neighbor_hexes())
	var sender_hex = Hex.new(5, -2)
	var edge_dir = origin.get_edge_direction(sender_hex)
	var target_chunk_hex = Hex.neighbor(Hex.new(0, 0), ChunkTopology.to_world_direction(edge_dir))
	var target = world.get_chunk(target_chunk_hex)
	var receiver_hex = ChunkTopology.mirror_hex(sender_hex, edge_dir)
	origin.place_piece(SENDER, sender_hex, 0)
	target.place_piece(RECEIVER, receiver_hex, 0)

	var sender_pos = origin.position + origin.hex_to_pixel(sender_hex)
	var receiver_pos = target.position + target.hex_to_pixel(receiver_hex)
	var spacing = origin.hex_to_pixel(Hex.new(1, 0)).length()
	print("Sender %s 画面位置 %s" % [sender_hex, sender_pos])
	print("Receiver %s (chunk %s) 画面位置 %s" % [receiver_hex, target_chunk_hex, receiver_pos])
	print("距離 %.1f / マス1つ分 %.1f" % [sender_pos.distance_to(receiver_pos), spacing])
	print("接続: ", not origin.get_piece_at_hex(sender_hex).get_connected_pieces().is_empty())

	scene._hover_local(receiver_pos)
	await scene.get_tree().process_frame
	print("隣の Receiver にホバー → 情報: ", scene.hud.info_panel.name_label.text, " 表示=", scene.hud.info_panel.visible)
	print("置こうとした結果（隣の chunk の中には置けない）: ", scene.piece_placer.place_piece_at_hex(Hex.new(-2, 8)))
