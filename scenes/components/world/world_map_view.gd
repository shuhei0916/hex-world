class_name WorldMapView
extends Node2D

const ChunkTileScript = preload("res://scenes/components/world/chunk_tile.gd")
const TILE_SIZE := 80.0

var _tiles: Dictionary = {}  # Hex.to_key → ChunkTile
var _active_hex = null
var _map_layout: Layout


func _init() -> void:
	_map_layout = Layout.new(Layout.layout_flat, Vector2(TILE_SIZE, TILE_SIZE), Vector2.ZERO)


func setup(world: World) -> void:
	for child in get_children():
		child.queue_free()
	_tiles.clear()
	_active_hex = null

	for hex in world.get_chunk_hexes():
		var tile = ChunkTileScript.new()
		tile.setup(hex)
		tile.position = Layout.hex_to_pixel(_map_layout, hex)
		add_child(tile)
		_tiles[Hex.to_key(hex)] = tile


func set_active_chunk(chunk_hex: Hex) -> void:
	if _active_hex != null:
		var prev = _tiles.get(Hex.to_key(_active_hex))
		if prev:
			prev.set_active(false)
	_active_hex = chunk_hex
	var tile = _tiles.get(Hex.to_key(chunk_hex))
	if tile:
		tile.set_active(true)


func get_tile_count() -> int:
	return _tiles.size()


func get_tile_position(chunk_hex: Hex) -> Vector2:
	var tile = _tiles.get(Hex.to_key(chunk_hex))
	return tile.position if tile else Vector2.ZERO


func get_tile_active(chunk_hex: Hex) -> bool:
	var tile = _tiles.get(Hex.to_key(chunk_hex))
	return tile.is_active if tile else false


func chunk_at_local_pos(local_pos: Vector2):
	var hex = Layout.pixel_to_hex_rounded(_map_layout, local_pos)
	var key = Hex.to_key(hex)
	if key in _tiles:
		return hex
	return null
