extends RefCounted
## planet チェストで、離れた chunk から別の chunk へアイテムが渡るかを出力する。
##
## 配置:
##   山岳の chunk: コンベア (-4,3) → planet 搬入チェスト (-3,3)。コンベアに銅鉱石を流し続ける。
##   原点の chunk(0,0): planet 搬出チェスト (-2,0) → コンベア (-1,0) → ハブ (0,0)。
## 2つの chunk は隣り合っておらず、Sender/Receiver も使わない。

const CONVEYOR = preload("res://scenes/components/piece/conveyor.tscn")
const PLANET_IN = preload("res://scenes/components/piece/planet_chest_in.tscn")
const PLANET_OUT = preload("res://scenes/components/piece/planet_chest_out.tscn")
const RUN_SECONDS := 8.0


func run(scene: Node) -> void:
	var world: World = scene.world
	var home: Chunk = world.get_active_chunk()
	home.place_piece(PLANET_OUT, Hex.new(-2, 0))
	home.place_piece(CONVEYOR, Hex.new(-1, 0))
	home.get_piece_at_hex(Hex.new(-2, 0)).get_node("ChestOutput").select_item("copper_ore")

	var far_hex = _far_mountain_hex(world.get_planet())
	scene._handle_world_map_chunk_selected(far_hex)
	var far: Chunk = world.get_active_chunk()
	far.place_piece(CONVEYOR, Hex.new(-4, 3))
	far.place_piece(PLANET_IN, Hex.new(-3, 3))
	var feeder: Piece = far.get_piece_at_hex(Hex.new(-4, 3))
	print(
		(
			"山岳の chunk=%s（原点からの距離 %d） / いま見ている chunk=%s"
			% [far_hex, Hex.distance(Hex.new(0, 0), far_hex), world.get_active_hex()]
		)
	)

	var elapsed := 0.0
	while elapsed < RUN_SECONDS:
		if feeder.can_accept_item("copper_ore"):
			feeder.add_item("copper_ore", 1)
		await scene.get_tree().process_frame
		elapsed += scene.get_process_delta_time()

	print(
		(
			"[%d秒後] 惑星の倉庫=%s / ハブに届いた銅鉱石=%d / 各 chunk の倉庫: 原点=%s 山岳=%s"
			% [
				RUN_SECONDS,
				world.planet_storage.get_contents(),
				HubGoals.get_stock("copper_ore"),
				home.storage.get_contents(),
				far.storage.get_contents(),
			]
		)
	)


# 原点と隣り合っていない山岳の chunk
func _far_mountain_hex(planet: Planet) -> Hex:
	for hex in planet.get_chunk_hexes():
		if planet.get_biome_id(hex) == Biome.MOUNTAINS and Hex.distance(Hex.new(0, 0), hex) >= 2:
			return hex
	return null
