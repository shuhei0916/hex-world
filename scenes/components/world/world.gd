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
	chunk.piece_placed.connect(_on_piece_placed)
	chunk.piece_removed.connect(_rewire_all_senders)
	return chunk


# ---- チャンク間配線 ---------------------------------------------------------
# Sender の接続先は隣接チャンクの点対称位置にある Receiver。
# 搬送自体は既存の acceptor/ejector 機構がそのまま行うため、World は配線のみを担う。


func _on_piece_placed(piece: Piece):
	if piece.piece_type == PieceData.Type.SENDER or piece.piece_type == PieceData.Type.RECEIVER:
		_rewire_all_senders()


func _rewire_all_senders():
	for chunk_hex in _chunk_hexes:
		var chunk = get_chunk(chunk_hex)
		for piece in chunk.get_all_pieces():
			if piece.piece_type == PieceData.Type.SENDER:
				_wire_sender(chunk_hex, chunk, piece)


func _wire_sender(chunk_hex: Hex, chunk: Chunk, sender: Piece):
	var base_hex = chunk.get_base_hex(sender)
	var edge_dir = chunk.get_edge_direction(base_hex)
	var receiver = _find_receiver(chunk_hex, base_hex, edge_dir)
	if receiver:
		sender.set_connected_pieces([receiver], [edge_dir])
	else:
		sender.set_connected_pieces([])


func _find_receiver(chunk_hex: Hex, sender_hex: Hex, edge_dir: int):
	if edge_dir == -1:
		return null
	var target_chunk = get_chunk(Hex.neighbor(chunk_hex, edge_dir))
	if target_chunk == null:
		return null
	var piece = target_chunk.get_piece_at_hex(Hex.scale(sender_hex, -1))
	if piece and piece.piece_type == PieceData.Type.RECEIVER:
		return piece
	return null


# chunk_hex のチャンクに向いた隣接チャンクの Sender の点対称位置（＝Receiver を置くべき位置）を返す
func get_receiver_hint_hexes(chunk_hex: Hex) -> Array:
	var result = []
	for other_hex in _chunk_hexes:
		var other = get_chunk(other_hex)
		for piece in other.get_all_pieces():
			if piece.piece_type != PieceData.Type.SENDER:
				continue
			var sender_hex = other.get_base_hex(piece)
			var edge_dir = other.get_edge_direction(sender_hex)
			if edge_dir == -1:
				continue
			if Hex.to_key(Hex.neighbor(other_hex, edge_dir)) == Hex.to_key(chunk_hex):
				result.append(Hex.scale(sender_hex, -1))
	return result


func get_chunk_hexes() -> Array[Hex]:
	return _chunk_hexes.duplicate()


func get_chunk(chunk_hex: Hex):
	return _chunks.get(Hex.to_key(chunk_hex), null)


func get_active_hex():
	return _active_hex


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
