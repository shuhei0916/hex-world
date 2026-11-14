class_name World
extends Node2D

# 1 chunk あたりの鉱床のマス数
const DEPOSIT_SIZE := 5

var _chunks: Dictionary = {}
var _chunk_hexes: Array[Hex] = []  # 生成済み chunk の座標
var _active_hex = null
var _planet: Planet = null


# planet を設定する。chunk の実体は初めてアクティブにしたときに生成する（遅延生成）。
func setup_planet(planet: Planet) -> void:
	_planet = planet


func get_planet() -> Planet:
	return _planet


# generate_deposits=false はセーブデータからの復元用（鉱床は保存された配置を使う）
func create_chunk(chunk_hex: Hex, generate_deposits: bool = true) -> Chunk:
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
	if generate_deposits:
		_generate_biome_deposits(chunk_hex, chunk)
	return chunk


func _generate_biome_deposits(chunk_hex: Hex, chunk: Chunk) -> void:
	if _planet == null:
		return
	var biome = _planet.get_biome(chunk_hex)
	if biome:
		chunk.generate_ore_deposits(DEPOSIT_SIZE, biome.resource_type)


# ---- チャンク間配線 ---------------------------------------------------------
# Sender の接続先は隣接チャンクの点対称位置にある Receiver。
# 搬送自体は既存の acceptor/ejector 機構がそのまま行うため、World は配線のみを担う。


func _on_piece_placed(piece: Piece):
	if piece.piece_type == PieceData.Type.SENDER or piece.piece_type == PieceData.Type.RECEIVER:
		_rewire_all_senders()


# edge_dirが有効なSenderを全チャンクから列挙する。
# 各要素: {chunk_hex, chunk, piece, base_hex, edge_dir}
func _iter_senders() -> Array:
	var result = []
	for chunk_hex in _chunk_hexes:
		var chunk = get_chunk(chunk_hex)
		for piece in chunk.get_all_pieces():
			if piece.piece_type != PieceData.Type.SENDER:
				continue
			var base_hex = chunk.get_base_hex(piece)
			var edge_dir = chunk.get_edge_direction(base_hex)
			if edge_dir == -1:
				continue
			(
				result
				. append(
					{
						"chunk_hex": chunk_hex,
						"chunk": chunk,
						"piece": piece,
						"base_hex": base_hex,
						"edge_dir": edge_dir,
					}
				)
			)
	return result


func _rewire_all_senders():
	for entry in _iter_senders():
		_wire_sender(entry["chunk_hex"], entry["base_hex"], entry["edge_dir"], entry["piece"])
	_update_receiver_hints()


func _wire_sender(chunk_hex: Hex, base_hex: Hex, edge_dir: int, sender: Piece):
	var receiver = _find_receiver(chunk_hex, base_hex, edge_dir)
	if receiver:
		sender.set_connected_pieces([receiver], [edge_dir])
	else:
		sender.set_connected_pieces([])


func _find_receiver(chunk_hex: Hex, sender_hex: Hex, edge_dir: int):
	var target_chunk = get_chunk(
		Hex.neighbor(chunk_hex, ChunkTopology.to_world_direction(edge_dir))
	)
	if target_chunk == null:
		return null
	var piece = target_chunk.get_piece_at_hex(ChunkTopology.mirror_hex(sender_hex, edge_dir))
	if piece and piece.piece_type == PieceData.Type.RECEIVER:
		return piece
	return null


# chunk_hex のチャンクに向いた隣接チャンクの Sender の点対称位置（＝Receiver を置くべき位置）を返す
func get_receiver_hint_hexes(chunk_hex: Hex) -> Array:
	var result = []
	for entry in _iter_senders():
		var target_hex = Hex.neighbor(
			entry["chunk_hex"], ChunkTopology.to_world_direction(entry["edge_dir"])
		)
		if Hex.to_key(target_hex) != Hex.to_key(chunk_hex):
			continue
		var mirror = ChunkTopology.mirror_hex(entry["base_hex"], entry["edge_dir"])
		if get_chunk(chunk_hex).get_piece_at_hex(mirror) == null:
			result.append(mirror)
	return result


# 実際に接続が成立している Sender→Receiver のチャンクペア(sender側hex, receiver側hex)一覧を返す。
func get_connected_chunk_pairs() -> Array:
	var result = []
	for entry in _iter_senders():
		if entry["piece"].get_connected_pieces().is_empty():
			continue
		var target_hex = Hex.neighbor(
			entry["chunk_hex"], ChunkTopology.to_world_direction(entry["edge_dir"])
		)
		result.append([entry["chunk_hex"], target_hex])
	return result


func get_chunk_hexes() -> Array[Hex]:
	return _chunk_hexes.duplicate()


# ワールドマップに並べる chunk の座標。planet があれば未生成の chunk も含む。
func get_map_hexes() -> Array[Hex]:
	if _planet:
		return _planet.get_chunk_hexes()
	return get_chunk_hexes()


func get_chunk(chunk_hex: Hex):
	return _chunks.get(Hex.to_key(chunk_hex), null)


func get_active_hex():
	return _active_hex


func get_active_chunk() -> Chunk:
	if _active_hex == null:
		return null
	return get_chunk(_active_hex)


func set_active_chunk(chunk_hex: Hex):
	if _planet and not _planet.has_chunk(chunk_hex):
		return
	if get_chunk(chunk_hex) == null:
		create_chunk(chunk_hex)
	if _active_hex != null:
		var prev = get_chunk(_active_hex)
		if prev:
			prev.visible = false
	_active_hex = chunk_hex
	var chunk = get_chunk(chunk_hex)
	if chunk:
		chunk.visible = true
	_update_receiver_hints()


func _update_receiver_hints():
	var chunk = get_active_chunk()
	if chunk == null:
		return
	chunk.show_receiver_hints(get_receiver_hint_hexes(_active_hex))
