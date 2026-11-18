extends RefCounted
## 石灰岩の台地の chunk に入り、鉱床に Miner を置いて石灰石が掘れるか、
## 窯で石灰石 → 生石灰、混合機で生石灰 + 砂 → コンクリートが実ゲームの tick で作られるかを出力する。
## あわせて、窯のスロットがレベルの報酬で開くことと、惑星に台地がいくつあるかを出す。

const MINER = preload("res://scenes/components/piece/miner_t1.tscn")
const KILN = preload("res://scenes/components/piece/kiln_t1.tscn")
const MIXER = preload("res://scenes/components/piece/mixer_t1.tscn")
const KILN_SLOT := 9
# t1 機械は加工時間2倍（コンクリート 4s×2=8s）なので、それより長く待つ
const WAIT_SECONDS := 9.0


func run(scene: Node) -> void:
	var planet: Planet = scene.world.get_planet()
	var counts := {}
	for hex in planet.get_chunk_hexes():
		var id = planet.get_biome_id(hex)
		counts[id] = counts.get(id, 0) + 1
	print("[planet] chunks per biome=%s" % counts)

	print("[slot] kiln locked at start=%s" % scene.hud.slot_buttons[KILN_SLOT].disabled)
	while HubGoals.get_current_goal()["reward"] != "unlock_kiln":
		HubGoals.advance_level()
	HubGoals.advance_level()
	print(
		(
			"[slot] after Lv%d reward: kiln locked=%s"
			% [HubGoals.level - 1, scene.hud.slot_buttons[KILN_SLOT].disabled]
		)
	)

	var chunk_hex = _first_hex_of(planet, Biome.PLATEAU)
	if chunk_hex == null:
		print("[plateau] 台地の chunk がない")
		return
	scene._handle_world_map_chunk_selected(chunk_hex)
	var chunk: Chunk = scene.world.get_active_chunk()
	var miner = _place_on_deposit(chunk)
	print(
		(
			"[plateau] chunk=%s miner recipe=%s"
			% [chunk_hex, miner.current_recipe.outputs if miner and miner.current_recipe else null]
		)
	)

	var kiln = _place_anywhere(chunk, KILN)
	var mixer = _place_anywhere(chunk, MIXER)
	kiln.add_item("limestone", 1)
	mixer.add_item("quicklime", 1)
	mixer.add_item("sand", 2)

	await scene.get_tree().create_timer(WAIT_SECONDS).timeout

	print("[after %.0fs] miner output=%s" % [WAIT_SECONDS, _output_of(miner)])
	for piece in [kiln, mixer]:
		var crafter = piece.get_node("Crafter")
		print(
			(
				"[after %.0fs] %s recipe=%s output=%s"
				% [
					WAIT_SECONDS,
					piece.piece_name,
					crafter.current_recipe.id if crafter.current_recipe else null,
					_output_of(piece)
				]
			)
		)


func _output_of(piece: Piece) -> Dictionary:
	var result = {}
	for id in ["limestone", "quicklime", "sand", "concrete"]:
		var n = piece.get_item_count(id)
		if n > 0:
			result[id] = n
	return result


func _place_on_deposit(chunk: Chunk) -> Piece:
	for hex in chunk.get_all_hexes():
		if chunk.get_hex_resource(hex) == "":
			continue
		var shape = MINER.instantiate()
		var offsets = shape.get_hex_shape()
		shape.free()
		if chunk.can_place(offsets, hex):
			chunk.place_piece(MINER, hex)
			return chunk.get_piece_at_hex(hex)
	return null


func _place_anywhere(chunk: Chunk, scene_res: PackedScene) -> Piece:
	var probe = scene_res.instantiate()
	var offsets = probe.get_hex_shape()
	probe.free()
	for hex in chunk.get_all_hexes():
		if chunk.get_hex_resource(hex) == "" and chunk.can_place(offsets, hex):
			chunk.place_piece(scene_res, hex)
			return chunk.get_piece_at_hex(hex)
	return null


func _first_hex_of(planet: Planet, biome_id: String) -> Variant:
	for hex in planet.get_chunk_hexes():
		if planet.get_biome_id(hex) == biome_id:
			return hex
	return null
