extends RefCounted

# planet のバイオーム分布を文字で描き、ワールドマップのホバー表示と
# 未生成 chunk への入場（遅延生成と鉱床）を確認する。
# 記号: P=平原 M=山岳 F=森林、* は原点

const SYMBOLS = {"plains": "P", "mountains": "M", "forest": "F"}


func run(scene: Node) -> void:
	var planet: Planet = scene.world.get_planet()
	_print_map(planet)

	scene._enter_world_map_mode()
	for biome_id in Biome.all_ids():
		var hex = _first_hex_of(planet, biome_id)
		scene.world_map_view.set_hovered_chunk(hex)
		print(
			(
				"[hover] %s -> %s"
				% [hex, scene.world_map_view.get_hover_info_text().replace("\n", " / ")]
			)
		)

		scene._handle_world_map_chunk_selected(hex)
		var chunk = scene.world.get_active_chunk()
		var resources = {}
		for h in chunk.get_all_hexes():
			var r = chunk.get_hex_resource(h)
			if r != "":
				resources[r] = resources.get(r, 0) + 1
		print("[enter] %s local=%s deposits=%s" % [hex, scene.is_local_mode(), resources])
		scene._enter_world_map_mode()
	print(
		(
			"[generated chunks] %d / %d"
			% [scene.world.get_chunk_hexes().size(), planet.get_chunk_hexes().size()]
		)
	)


func _first_hex_of(planet: Planet, biome_id: String) -> Hex:
	for hex in planet.get_chunk_hexes():
		if planet.get_biome_id(hex) == biome_id and not Hex.equals(hex, Hex.new(0, 0)):
			return hex
	return null


# flat-top レイアウトを列(q)ごとに半段ずらして描く
func _print_map(planet: Planet) -> void:
	var radius = planet.radius
	for row in range(-radius * 2, radius * 2 + 1):
		var line = ""
		for q in range(-radius, radius + 1):
			# flat-top では y ∝ 2r + q。row = 2r + q を満たす r が整数のときだけ描く
			var cell = "  "
			if (row - q) % 2 == 0:
				var hex = Hex.new(q, (row - q) / 2)
				if planet.has_chunk(hex):
					var symbol = SYMBOLS.get(planet.get_biome_id(hex), "?")
					cell = ("*" if Hex.equals(hex, Hex.new(0, 0)) else " ") + symbol
			line += cell
		print(line)
