class_name Biome
extends RefCounted

# Biome - 惑星上の地域の種類。バイオームごとに採れる資源とマップ上の色が決まる。

const PLAINS := "plains"
const MOUNTAINS := "mountains"
const FOREST := "forest"
const DESERT := "desert"
const PLATEAU := "plateau"

static var _biomes: Dictionary = {}

var id: String
var display_name: String
var map_color: Color
var resource_type: String


func _init(id_val: String, name_val: String, color_val: Color, resource_val: String) -> void:
	id = id_val
	display_name = name_val
	map_color = color_val
	resource_type = resource_val


static func _ensure_defaults() -> void:
	if not _biomes.is_empty():
		return
	for biome in [
		Biome.new(PLAINS, "平原", Color("#5a8c3a"), "iron_ore"),
		Biome.new(MOUNTAINS, "山岳", Color("#8c6a4a"), "copper_ore"),
		Biome.new(FOREST, "森林", Color("#2a5a3a"), "coal"),
		Biome.new(DESERT, "砂丘", Color("#c2a35e"), "sand"),
		Biome.new(PLATEAU, "石灰岩の台地", Color("#a9a48f"), "limestone"),
	]:
		_biomes[biome.id] = biome


static func get_biome(biome_id: String) -> Biome:
	_ensure_defaults()
	return _biomes.get(biome_id)


static func all_ids() -> Array[String]:
	_ensure_defaults()
	var ids: Array[String] = []
	ids.assign(_biomes.keys())
	return ids
