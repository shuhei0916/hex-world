class_name WorldMapView
extends Node2D

const ChunkTileScript = preload("res://scenes/components/world/chunk_tile.gd")
const TILE_SIZE := 80.0

const CONNECTION_ARROW_TEXTURE = preload("res://scenes/components/piece/forward.png")
const CONNECTION_ARROW_COLOR = Color(0.5, 1.0, 0.5, 1)

var _tiles: Dictionary = {}  # Hex.to_key → ChunkTile
var _active_hex = null
var _map_layout: Layout
var _connection_arrows: Array = []


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
