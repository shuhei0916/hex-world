class_name World
extends Node2D

# 1 chunk あたりの鉱床のマス数
const DEPOSIT_SIZE := 5
# ローカル画面で、アクティブな chunk の周りに描く隣の chunk の色（操作できないので暗くする）。
# 暗くしすぎると床のタイルが背景(0.13)に溶けて見えなくなる
const NEIGHBOR_MODULATE := Color(0.78, 0.78, 0.8, 1.0)
# 隣の chunk との間に空ける溝の幅（タイル何個分か）。境界がひと目で分かるようにする
const GAP_TILES := 2.0

# planet チェストが共有する、惑星全体で1つの倉庫
var planet_storage := SharedStorage.new()

var _chunks: Dictionary = {}
var _chunk_hexes: Array[Hex] = []  # 生成済み chunk の座標
var _active_hex = null
var _neighbor_hexes: Array[Hex] = []  # アクティブな chunk の周りに描いている chunk
var _planet: Planet = null
# バイオームチェストが共有する倉庫。地域（Planet の region）ごとに1つ {地域番号: SharedStorage}
var _region_storages: Dictionary = {}


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
	chunk.storage_resolver = _resolve_storage.bind(chunk_hex)
	chunk.piece_placed.connect(_on_piece_placed)
	chunk.piece_removed.connect(_rewire_all_senders)
	if generate_deposits:
		_generate_biome_deposits(chunk_hex, chunk)
	return chunk


# chunk_hex の chunk から見た、chunk より広い共有範囲の倉庫を返す。
# 該当する倉庫が無ければ null（その場合チェストは chunk の倉庫を使う）。
func _resolve_storage(scope: String, chunk_hex: Hex) -> SharedStorage:
	if scope == SharedStorage.SCOPE_PLANET:
		return planet_storage
	if scope == SharedStorage.SCOPE_BIOME and _planet and _planet.has_chunk(chunk_hex):
		return get_region_storage(_planet.get_region_id(chunk_hex))
	return null


# 地域の倉庫（初めて使うときに作る）
func get_region_storage(region_id: int) -> SharedStorage:
	if not _region_storages.has(region_id):
		_region_storages[region_id] = SharedStorage.new()
	return _region_storages[region_id]


# 中身のある地域の倉庫 {地域番号: 中身}（セーブ用）
func get_region_storage_contents() -> Dictionary:
	var result := {}
	for region_id in _region_storages:
		var contents = _region_storages[region_id].get_contents()
		if not contents.is_empty():
			result[region_id] = contents
	return result


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
	_active_hex = chunk_hex
	_layout_visible_chunks()
	_update_receiver_hints()


# アクティブな chunk の周りに描いている隣の chunk の座標
func get_neighbor_hexes() -> Array[Hex]:
	return _neighbor_hexes.duplicate()


# 隣の chunk を描く位置。敷き詰めた位置から、境界の辺に垂直な向きへ溝の幅だけ離す。
# （中心どうしを結ぶ向きに離すと、敷き詰めのねじれのぶん境界に沿って斜めにずれる）
func _neighbor_position(active: Chunk, chunk_delta: Hex) -> Vector2:
	var offset = ChunkTopology.chunk_offset(chunk_delta, active.grid_radius)
	var tiled = active.hex_to_pixel(offset)
	var world_dir = range(6).filter(func(d): return Hex.equals(Hex.direction(d), chunk_delta))[0]
	var edge_dir = (world_dir + 5) % 6  # to_world_direction の逆
	var normal = active.hex_to_pixel(Hex.direction(edge_dir))
	return tiled + normal * GAP_TILES


# 画面上の位置（World の座標）にある施設。アクティブな chunk と、周りに描いている隣の chunk を探す
func get_piece_at_position(pos: Vector2) -> Piece:
	var hexes: Array[Hex] = []
	if _active_hex != null:
		hexes.append(_active_hex)
	hexes.append_array(_neighbor_hexes)
	for chunk_hex in hexes:
		var chunk = get_chunk(chunk_hex)
		var hex = Layout.pixel_to_hex_rounded(chunk.layout, pos - chunk.position)
		if chunk.is_inside_grid(hex):
			return chunk.get_piece_at_hex(hex)
	return null


# アクティブな chunk を原点に、隣の chunk を敷き詰めた位置に並べて表示する。
# planet があれば、隣は見えるように生成する（見えた chunk はセーブにも残る）。それ以外は隠す。
func _layout_visible_chunks() -> void:
	_neighbor_hexes.clear()
	for dir in range(6):
		var hex = Hex.neighbor(_active_hex, dir)
		if _planet and _planet.has_chunk(hex):
			create_chunk(hex)
		if get_chunk(hex) != null:
			_neighbor_hexes.append(hex)
	for chunk_hex in _chunk_hexes:
		get_chunk(chunk_hex).visible = false
	var active = get_active_chunk()
	active.visible = true
	active.position = Vector2.ZERO
	active.modulate = Color.WHITE
	for hex in _neighbor_hexes:
		var chunk = get_chunk(hex)
		chunk.visible = true
		chunk.position = _neighbor_position(active, Hex.subtract(hex, _active_hex))
		chunk.modulate = NEIGHBOR_MODULATE


func _update_receiver_hints():
	var chunk = get_active_chunk()
	if chunk == null:
		return
	chunk.show_receiver_hints(get_receiver_hint_hexes(_active_hex))
