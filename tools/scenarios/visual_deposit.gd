extends RefCounted

## 見た目の確認用（screenshot.sh と組み合わせる）。鉱床のマスの1つに Miner を置き、
## 鉱床（地面の種類）と設置物の本体が見分けられるかを拡大して映す。

const MINER = preload("res://scenes/components/piece/miner_t1.tscn")


func run(scene: Node) -> void:
	HubGoals.creative_mode = true
	var chunk: Chunk = scene.world.get_active_chunk()
	var deposits: Array[Vector2i] = []
	for hex in chunk.get_all_hexes():
		if chunk.get_hex_resource(hex) != "":
			deposits.append(hex)
	print("鉱床: ", deposits)
	if deposits.is_empty():
		return
	# place_piece は置けるかを確かめないので、ハブなどに重ならない鉱床を選ぶ
	var probe: Piece = MINER.instantiate()
	var shape := probe.get_hex_shape()
	probe.free()
	var target = null
	for hex in deposits:
		if chunk.can_place(shape, hex):
			target = hex
			break
	print("Miner を置く鉱床: ", target)
	if target == null:
		return
	chunk.place_piece(MINER, target, 0)
	scene.camera.position = chunk.hex_to_pixel(target)
	scene.camera.zoom = Vector2(2.0, 2.0)
	for i in 10:
		await scene.get_tree().process_frame
