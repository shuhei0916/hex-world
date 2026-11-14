extends RefCounted

## 見た目の確認用の配置（screenshot.sh と組み合わせる）。
## 鉱床の Miner → コンベア → Smelter → コンベア → ハブ、境界の橋と、隣の chunk で受け取るコンベアを置き、
## 少し流してから撮れる状態にする。カメラは CAMERA_ZOOM で引いて隣の chunk も映す。

const CONVEYOR = preload("res://scenes/components/piece/conveyor.tscn")
const MINER = preload("res://scenes/components/piece/miner_t1.tscn")
const SMELTER = preload("res://scenes/components/piece/smelter_t1.tscn")
const SENDER = preload("res://scenes/components/piece/bridge.tscn")

const CAMERA_ZOOM := 0.55


func run(scene: Node) -> void:
	HubGoals.creative_mode = true
	HubGoals.gained_rewards["unlock_smelter"] = true
	var world: World = scene.world
	var chunk: Chunk = world.get_active_chunk()
	var ore_hex = _first_resource_hex(chunk)
	print("鉱床: ", ore_hex)
	# Smelter は (-3,3) を基点に (-4,3), (-3,4) を占め、(-3,3) の東の辺から出す
	chunk.place_piece(SMELTER, Hex.new(-3, 3), 0)
	# 入口: 西から (-4,3) へ、北西から (-3,3) へ流し込む
	chunk.place_piece(CONVEYOR, Hex.new(-6, 3), 0)
	chunk.place_piece(CONVEYOR, Hex.new(-5, 3), 0)
	chunk.place_piece(CONVEYOR, Hex.new(-3, 2), 5)
	# 出口: 東へ流してハブ(0,0)の南西の辺へ
	chunk.place_piece(CONVEYOR, Hex.new(-2, 3), 0)
	chunk.place_piece(CONVEYOR, Hex.new(-1, 3), 1)
	chunk.place_piece(CONVEYOR, Hex.new(0, 2), 2)
	chunk.place_piece(CONVEYOR, Hex.new(0, 1), 2)
	print("Smelter の出力: ", chunk.get_piece_at_hex(Hex.new(-3, 3)).get_output_ports())
	chunk.place_piece(SENDER, Hex.new(5, -2), 0)
	var edge_dir = chunk.get_edge_direction(Hex.new(5, -2))
	var target_hex = Hex.neighbor(Hex.new(0, 0), ChunkTopology.to_world_direction(edge_dir))
	world.get_chunk(target_hex).place_piece(
		CONVEYOR, ChunkTopology.mirror_hex(Hex.new(5, -2), edge_dir), 0
	)
	scene.camera.zoom = Vector2(CAMERA_ZOOM, CAMERA_ZOOM)
	for i in 60:
		await scene.get_tree().process_frame


func _first_resource_hex(chunk: Chunk):
	for hex in chunk.get_all_hexes():
		if chunk.get_hex_resource(hex) != "":
			return hex
	return null
