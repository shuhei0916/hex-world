extends RefCounted

## ワールドマップの輸送のカードの見た目の確認用（screenshot.sh と組み合わせる）。
## 原点 chunk の東の辺に橋を2本（鉄鉱石・銅鉱石）、東隣から原点へ戻す橋を1本（石炭）架けて
## しばらく流し、ワールドマップへ切り替える。環境変数 MAP_ZOOM でカメラの倍率を変えられる。
## 受け取り側のコンベアは毎フレーム空にして、詰まらずに流れ続けるようにする。

const BRIDGE = preload("res://scenes/components/piece/bridge.tscn")
const CONVEYOR = preload("res://scenes/components/piece/conveyor.tscn")
const FRAMES := 420


func run(scene: Node) -> void:
	HubGoals.creative_mode = true
	var world: World = scene.world
	var origin: Chunk = world.get_active_chunk()
	var radius = origin.grid_radius
	var east_hex = Hex.neighbor(Vector2i(0, 0), ChunkTopology.to_world_direction(0))
	world.territory.claim(east_hex)
	var east: Chunk = world.get_chunk(east_hex)
	if east == null:
		east = world.create_chunk(east_hex)

	var feeds := []  # [橋, 流す品目の一覧]
	var sinks := []  # 受け取り側のコンベア
	feeds.append([_bridge(origin, east, Vector2i(radius, -2), 0, sinks), ["iron_ore"]])
	feeds.append(
		[
			_bridge(origin, east, Vector2i(radius, -4), 0, sinks),
			["iron_ore", "copper_ore", "copper_ore"]
		]
	)
	feeds.append([_bridge(east, origin, Vector2i(-radius, 3), 3, sinks), ["coal"]])

	for frame in FRAMES:
		for feed in feeds:
			var bridge: Piece = feed[0]
			if bridge.conveyor_logic.can_accept_item(""):
				var items: Array = feed[1]
				bridge.add_item(items[frame % items.size()], 1)
		for sink in sinks:
			sink.conveyor_logic._buffer.clear()
		await scene.get_tree().process_frame

	scene._enter_world_map_mode()
	var zoom = float(OS.get_environment("MAP_ZOOM")) if OS.has_environment("MAP_ZOOM") else 0.0
	if zoom > 0.0:
		scene.camera.zoom = Vector2(zoom, zoom)
	var transfers = world.get_chunk_transfers()
	print("[transfers] %s" % [transfers])


func _bridge(from: Chunk, to: Chunk, hex: Vector2i, edge_dir: int, sinks: Array) -> Piece:
	from.place_piece(BRIDGE, hex, 0)
	var landing = ChunkTopology.mirror_hex(hex, edge_dir)
	to.place_piece(CONVEYOR, landing, edge_dir)
	sinks.append(to.get_piece_at_hex(landing))
	return from.get_piece_at_hex(hex)
