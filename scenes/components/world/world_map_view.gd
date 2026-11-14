class_name WorldMapView
extends Node2D

const ChunkTileScript = preload("res://scenes/components/world/chunk_tile.gd")
const TILE_SIZE := 80.0

const CONNECTION_ARROW_TEXTURE = preload("res://scenes/components/piece/forward.png")
const CONNECTION_ARROW_COLOR = Color(0.5, 1.0, 0.5, 1)
const INFO_LABEL_SIZE := Vector2(120, 48)

var _tiles: Dictionary = {}  # Hex.to_key → ChunkTile
var _active_hex = null
var _hovered_hex = null
var _map_layout: Layout
var _connection_arrows: Array = []
var _planet: Planet = null
var _info_label: Label = null


func _init() -> void:
	_map_layout = Layout.new(Layout.layout_flat, Vector2(TILE_SIZE, TILE_SIZE), Vector2.ZERO)


func setup(world: World) -> void:
	for child in get_children():
		child.queue_free()
	_tiles.clear()
	_connection_arrows.clear()
	_active_hex = null
	_hovered_hex = null
	_planet = world.get_planet()

	for hex in world.get_map_hexes():
		var tile = ChunkTileScript.new()
		tile.setup(hex, _tile_color(hex))
		tile.position = Layout.hex_to_pixel(_map_layout, hex)
		add_child(tile)
		_tiles[Hex.to_key(hex)] = tile

	_info_label = Label.new()
	_info_label.size = INFO_LABEL_SIZE
	_info_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_info_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_info_label.z_index = 1  # 隣のタイルより手前に出す
	_info_label.visible = false
	add_child(_info_label)


func _tile_color(hex: Hex) -> Color:
	var biome = _planet.get_biome(hex) if _planet else null
	return biome.map_color if biome else ChunkTileScript.NORMAL_COLOR


func set_active_chunk(chunk_hex: Hex) -> void:
	if _active_hex != null:
		var prev = _tiles.get(Hex.to_key(_active_hex))
		if prev:
			prev.set_active(false)
	_active_hex = chunk_hex
	var tile = _tiles.get(Hex.to_key(chunk_hex))
	if tile:
		tile.set_active(true)


func set_hovered_chunk(chunk_hex) -> void:
	if _hovered_hex != null:
		var prev = _tiles.get(Hex.to_key(_hovered_hex))
		if prev:
			prev.set_hovered(false)
	_hovered_hex = chunk_hex
	_update_info_label()
	if chunk_hex == null:
		return
	var tile = _tiles.get(Hex.to_key(chunk_hex))
	if tile:
		tile.set_hovered(true)


# ホバー中の chunk のバイオームと採れる資源をタイル上に表示する
func _update_info_label() -> void:
	if _info_label == null:
		return
	var biome = _planet.get_biome(_hovered_hex) if _planet and _hovered_hex else null
	if biome == null:
		_info_label.text = ""
		_info_label.visible = false
		return
	var item = ItemDB.get_item(biome.resource_type)
	var resource_name = item.display_name if item else biome.resource_type
	_info_label.text = "%s\n%s" % [biome.display_name, resource_name]
	_info_label.position = get_tile_position(_hovered_hex) - INFO_LABEL_SIZE / 2
	_info_label.visible = true


func get_hover_info_text() -> String:
	return _info_label.text if _info_label else ""


func get_tile_color(chunk_hex: Hex) -> Color:
	var tile = _tiles.get(Hex.to_key(chunk_hex))
	return tile.get_current_color() if tile else Color.TRANSPARENT


func get_tile_hovered(chunk_hex: Hex) -> bool:
	var tile = _tiles.get(Hex.to_key(chunk_hex))
	return tile.is_hovered if tile else false


func get_tile_count() -> int:
	return _tiles.size()


# 隣どうしのタイルの中心の距離。ローカル画面との縮尺合わせに使う
func get_tile_spacing() -> float:
	return Layout.hex_to_pixel(_map_layout, Hex.direction(0)).length()


func get_tile_position(chunk_hex: Hex) -> Vector2:
	var tile = _tiles.get(Hex.to_key(chunk_hex))
	return tile.position if tile else Vector2.ZERO


func get_tile_active(chunk_hex: Hex) -> bool:
	var tile = _tiles.get(Hex.to_key(chunk_hex))
	return tile.is_active if tile else false


func get_connection_arrow_count() -> int:
	return _connection_arrows.size()


func get_connection_arrow_position(index: int) -> Vector2:
	return _connection_arrows[index].position


func refresh_connections(pairs: Array) -> void:
	for arrow in _connection_arrows:
		remove_child(arrow)
		arrow.queue_free()
	_connection_arrows.clear()
	for pair in pairs:
		var from_tile = _tiles.get(Hex.to_key(pair[0]))
		var to_tile = _tiles.get(Hex.to_key(pair[1]))
		if from_tile == null or to_tile == null:
			continue
		var arrow = Sprite2D.new()
		arrow.texture = CONNECTION_ARROW_TEXTURE
		arrow.modulate = CONNECTION_ARROW_COLOR
		arrow.position = (from_tile.position + to_tile.position) / 2.0
		arrow.rotation = (to_tile.position - from_tile.position).angle()
		add_child(arrow)
		_connection_arrows.append(arrow)


func chunk_at_local_pos(local_pos: Vector2):
	var hex = Layout.pixel_to_hex_rounded(_map_layout, local_pos)
	var key = Hex.to_key(hex)
	if key in _tiles:
		return hex
	return null
