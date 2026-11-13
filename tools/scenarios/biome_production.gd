extends RefCounted
## 平原以外のバイオームの chunk に入り、鉱床に Miner を置いて新資源が採掘されるか、
## その資源を使うレシピ（銅インゴット・鋼材）が実ゲームの tick で加工されるかを出力する。

const MINER = preload("res://scenes/components/piece/miner_t1.tscn")
const SMELTER = preload("res://scenes/components/piece/smelter_t1.tscn")
const MIXER = preload("res://scenes/components/piece/mixer_t1.tscn")
# t1 機械は加工時間2倍（鋼材 4s×2=8s）なので、それより長く待つ
const WAIT_SECONDS := 9.0


func run(scene: Node) -> void:
	var planet: Planet = scene.world.get_planet()
	for biome_id in [Biome.MOUNTAINS, Biome.FOREST]:
		var chunk_hex = _first_hex_of(planet, biome_id)
		scene._handle_world_map_chunk_selected(chunk_hex)
		var chunk: Chunk = scene.world.get_active_chunk()
		var miner = _place_on_deposit(chunk)
		if miner == null:
			print("[%s] Miner を置ける鉱床がない" % biome_id)
			continue
		var recipe = miner.current_recipe
		print(
			(
				"[%s] chunk=%s miner recipe=%s multiplier=%d"
				% [
					biome_id,
					chunk_hex,
					recipe.outputs if recipe else null,
					miner.get_node("Crafter").output_multiplier
				]
			)
		)

	# 加工側: 最後に入った chunk に機械を置き、材料を手で投入して実ゲームの tick で加工させる
	var chunk: Chunk = scene.world.get_active_chunk()
	var smelter = _place_anywhere(chunk, SMELTER)
	var mixer = _place_anywhere(chunk, MIXER)
	smelter.add_item("copper_ore", 1)
	mixer.add_item("coal", 1)
	mixer.add_item("iron_ingot", 1)

	await scene.get_tree().create_timer(WAIT_SECONDS).timeout

	for piece in chunk.get_all_pieces():
		if piece.piece_type == PieceData.Type.MINER:
			print("[after %.0fs] miner output=%s" % [WAIT_SECONDS, _output_of(piece)])
	for piece in [smelter, mixer]:
		var crafter = piece.get_node("Crafter")
		print(
			(
				"[after %.0fs] %s recipe=%s progress=%.2f output=%s"
				% [
					WAIT_SECONDS,
					piece.piece_name,
					crafter.current_recipe.id if crafter.current_recipe else null,
					crafter.processing_progress,
					_output_of(piece)
				]
			)
		)


func _output_of(piece: Piece) -> Dictionary:
	var result = {}
	for id in ["copper_ore", "coal", "copper_ingot", "steel"]:
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


func _first_hex_of(planet: Planet, biome_id: String) -> Hex:
	for hex in planet.get_chunk_hexes():
		if planet.get_biome_id(hex) == biome_id:
			return hex
	return null
