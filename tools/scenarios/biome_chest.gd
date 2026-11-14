extends RefCounted
## バイオームチェストが「ひと続きの地域」の中だけで共有されるかを出力する。
##
## 配置:
##   原点の chunk(0,0): バイオーム搬出チェスト (-2,0) → コンベア (-1,0) → ハブ (0,0)。石炭と鉄鉱石を選んで試す。
##   原点と同じ地域の別の chunk: コンベア (-4,3) → バイオーム搬入チェスト (-3,3)。鉄鉱石を流す。
##   別の地域の chunk: 同じ配置で石炭を流す（こちらは原点に届かないはず）。

const CONVEYOR = preload("res://scenes/components/piece/conveyor.tscn")
const BIOME_IN = preload("res://scenes/components/piece/biome_chest_in.tscn")
const BIOME_OUT = preload("res://scenes/components/piece/biome_chest_out.tscn")
const RUN_SECONDS := 6.0


func run(scene: Node) -> void:
	var world: World = scene.world
	var planet: Planet = world.get_planet()
	var origin = Hex.new(0, 0)
	var home: Chunk = world.get_active_chunk()
	home.place_piece(BIOME_OUT, Hex.new(-2, 0))
	home.place_piece(CONVEYOR, Hex.new(-1, 0))
	var chest_out = home.get_piece_at_hex(Hex.new(-2, 0)).get_node("ChestOutput")

	var same_region = null
	var other_region = null
	for hex in planet.get_chunk_hexes():
		if Hex.equals(hex, origin):
			continue
		if planet.get_region_id(hex) == planet.get_region_id(origin):
			# 原点から最も遠い chunk を選ぶ（隣でなくても届くことを見る）
			if same_region == null or Hex.distance(origin, hex) > Hex.distance(origin, same_region):
				same_region = hex
		elif other_region == null:
			other_region = hex
	print(
		(
			"原点の地域=%d / 同じ地域の chunk=%s（距離 %d） / 別の地域の chunk=%s（地域 %d・%s）"
			% [
				planet.get_region_id(origin),
				same_region,
				Hex.distance(origin, same_region),
				other_region,
				planet.get_region_id(other_region),
				planet.get_biome_id(other_region),
			]
		)
	)

	var same_feeder = _build_input(scene, same_region)
	var other_feeder = _build_input(scene, other_region)

	chest_out.select_item("coal")
	await _feed(scene, {same_feeder: "iron_ore", other_feeder: "coal"})
	print("[石炭を選んで%d秒] %s" % [RUN_SECONDS, _summary(world, same_region, other_region)])

	chest_out.select_item("iron_ore")
	await _feed(scene, {same_feeder: "iron_ore", other_feeder: "coal"})
	print("[鉄鉱石を選んで%d秒] %s" % [RUN_SECONDS, _summary(world, same_region, other_region)])


func _build_input(scene: Node, chunk_hex: Hex) -> Piece:
	scene._handle_world_map_chunk_selected(chunk_hex)
	var chunk: Chunk = scene.world.get_active_chunk()
	chunk.place_piece(CONVEYOR, Hex.new(-4, 3))
	chunk.place_piece(BIOME_IN, Hex.new(-3, 3))
	return chunk.get_piece_at_hex(Hex.new(-4, 3))


func _feed(scene: Node, feeders: Dictionary) -> void:
	var elapsed := 0.0
	while elapsed < RUN_SECONDS:
		for feeder in feeders:
			if feeder.can_accept_item(feeders[feeder]):
				feeder.add_item(feeders[feeder], 1)
		await scene.get_tree().process_frame
		elapsed += scene.get_process_delta_time()


func _summary(world: World, same_region: Hex, other_region: Hex) -> String:
	var planet = world.get_planet()
	return (
		"ハブに届いた: 鉄鉱石=%d 石炭=%d / 原点の地域の倉庫=%s / 別の地域の倉庫=%s"
		% [
			HubGoals.get_stock("iron_ore"),
			HubGoals.get_stock("coal"),
			world.get_region_storage(planet.get_region_id(same_region)).get_contents(),
			world.get_region_storage(planet.get_region_id(other_region)).get_contents(),
		]
	)
