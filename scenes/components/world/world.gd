class_name World
extends Node2D

var _chunks: Dictionary = {}
var _chunk_hexes: Array[Hex] = []
var _active_hex = null


func create_chunk(chunk_hex: Hex) -> Chunk:
	var key = Hex.to_key(chunk_hex)
	if key in _chunks:
		return _chunks[key]
	var chunk = preload("res://scenes/components/chunk/chunk.gd").new()
	chunk.visible = false
	add_child(chunk)
	_chunks[key] = chunk
	_chunk_hexes.append(chunk_hex)
	return chunk


func get_chunk_hexes() -> Array[Hex]:
	return _chunk_hexes.duplicate()


func get_chunk(chunk_hex: Hex):
	return _chunks.get(Hex.to_key(chunk_hex), null)


func get_active_chunk() -> Chunk:
	if _active_hex == null:
		return null
	return get_chunk(_active_hex)


func set_active_chunk(chunk_hex: Hex):
	if _active_hex != null:
		var prev = get_chunk(_active_hex)
		if prev:
			prev.visible = false
	_active_hex = chunk_hex
	var chunk = get_chunk(chunk_hex)
	if chunk:
		chunk.visible = true
