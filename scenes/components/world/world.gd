class_name World
extends Node2D

# 1 chunk あたりの鉱床のマス数
const DEPOSIT_SIZE := 5
# ローカル画面で、アクティブな chunk の周りに描く隣の chunk の色（操作できないので暗くする）。
# 暗くしすぎると床のタイルが背景(0.13)に溶けて見えなくなる
const NEIGHBOR_MODULATE := Color(0.78, 0.78, 0.8, 1.0)
# 橋の帯の曲線を何本の線分で描くか
const BRIDGE_PATH_SEGMENTS := 16

# 隣の chunk との間の溝の幅。辺に垂直な斜め方向に何段ずらすか（1段 ≒ タイル0.7個分、
# 2段 ≒ 2.5個分、3段 ≒ 4.2個分）。境界がひと目で分かるようにする
static var gap_steps := 2

# planet チェストが共有する、惑星全体で1つの倉庫
var planet_storage := SharedStorage.new()

var _chunks: Dictionary = {}
var _chunk_hexes: Array[Hex] = []  # 生成済み chunk の座標
var _active_hex = null
var _neighbor_hexes: Array[Hex] = []  # アクティブな chunk の周りに描いている chunk
var _planet: Planet = null
# バイオームチェストが共有する倉庫。地域（Planet の region）ごとに1つ {地域番号: SharedStorage}
var _region_storages: Dictionary = {}


func _ready() -> void:
	var overlay := BridgeOverlay.new()
	overlay.name = "BridgeOverlay"
	add_child(overlay)


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
	chunk.piece_removed.connect(_rewire_all_bridges)
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


# ---- 橋（chunk 間の受け渡し） ----------------------------------------------
# 橋は chunk の辺に置き、溝の向こうの隣の chunk の向かいのマス（mirror_hex）にある
# コンベアや施設へアイテムを渡す。搬送自体は既存の acceptor/ejector 機構がそのまま行うため、
# World は配線と、溝の上の帯の描画に使う情報だけを担う。


# 向かいのマスはどの施設でも受け取り先になり得るので、何を置いても配線し直す
func _on_piece_placed(_piece: Piece):
	_rewire_all_bridges()


# 辺に置かれた橋を全 chunk から列挙する。
# 各要素: {chunk_hex, chunk, piece, base_hex, edge_dir, target_chunk_hex, landing_hex}
func _iter_bridges() -> Array:
	var result = []
	for chunk_hex in _chunk_hexes:
		var chunk = get_chunk(chunk_hex)
		for piece in chunk.get_all_pieces():
			if piece.piece_type != PieceData.Type.BRIDGE:
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
						"target_chunk_hex":
						Hex.neighbor(chunk_hex, ChunkTopology.to_world_direction(edge_dir)),
						"landing_hex": ChunkTopology.mirror_hex(base_hex, edge_dir),
					}
				)
			)
	return result


func _rewire_all_bridges():
	for entry in _iter_bridges():
		var target = _find_bridge_target(entry)
		if target:
			entry["piece"].set_connected_pieces([target], [entry["edge_dir"]])
		else:
			entry["piece"].set_connected_pieces([])
	_update_landing_hints()


# 橋の受け取り先。向かいのマスにあるピース。向かい合う橋どうしはつながない
# （つなぐと、アイテムが溝の上を行ったり来たりする）
func _find_bridge_target(entry: Dictionary):
	var target_chunk = get_chunk(entry["target_chunk_hex"])
	if target_chunk == null:
		return null
	var piece = target_chunk.get_piece_at_hex(entry["landing_hex"])
	if piece == null or piece.piece_type == PieceData.Type.BRIDGE:
		return null
	return piece


# chunk_hex の chunk に向いた橋の向かいのマスのうち、まだ何も置かれていないもの
# （受け取るコンベアや施設を置く場所）
func get_bridge_landing_hexes(chunk_hex: Hex) -> Array:
	var result = []
	var chunk = get_chunk(chunk_hex)
	if chunk == null:
		return result
	for entry in _iter_bridges():
		if not Hex.equals(entry["target_chunk_hex"], chunk_hex):
			continue
		if chunk.get_piece_at_hex(entry["landing_hex"]) == null:
			result.append(entry["landing_hex"])
	return result


# 溝の上に描く橋の帯（ローカル画面に描いている chunk どうしのものだけ）。画面上の位置で返す。
# 各要素: {from: 橋のマスの中心, to: 向かいのマスの中心, path: 帯の曲線, connected,
#          item: 渡している途中のアイテム, progress}
func get_bridge_spans() -> Array:
	var visible_keys := {}
	for chunk_hex in _visible_chunk_hexes():
		visible_keys[Hex.to_key(chunk_hex)] = true
	var spans = []
	for entry in _iter_bridges():
		if not visible_keys.has(Hex.to_key(entry["chunk_hex"])):
			continue
		if not visible_keys.has(Hex.to_key(entry["target_chunk_hex"])):
			continue
		var target_chunk = get_chunk(entry["target_chunk_hex"])
		var piece: Piece = entry["piece"]
		var logic = piece.get_node("ConveyorLogic")
		var from = entry["chunk"].position + entry["chunk"].hex_to_pixel(entry["base_hex"])
		var to = target_chunk.position + target_chunk.hex_to_pixel(entry["landing_hex"])
		var out = entry["chunk"].hex_to_pixel(Hex.direction(entry["edge_dir"])) * 0.5
		(
			spans
			. append(
				{
					"from": from,
					"to": to,
					"path": bridge_path(from + out, to - out, out.normalized()),
					"connected": piece.has_connected_piece(),
					"item": logic.get_held_item(),
					"progress": logic.get_progress_ratio(),
				}
			)
		)
	return spans


# 橋の帯の曲線。橋の外側の辺の中点 start から、着地点の向かい合う辺の中点 end まで。
# 両端では辺に垂直（normal の向き）に出入りするので、着地点のコンベアの入口とそのままつながる。
static func bridge_path(start: Vector2, end: Vector2, normal: Vector2) -> PackedVector2Array:
	var reach = start.distance_to(end) * 0.4
	var c1 = start + normal * reach
	var c2 = end - normal * reach
	var points := PackedVector2Array()
	for i in range(BRIDGE_PATH_SEGMENTS + 1):
		var t = float(i) / BRIDGE_PATH_SEGMENTS
		var mt = 1.0 - t
		points.append(
			mt * mt * mt * start + 3.0 * mt * mt * t * c1 + 3.0 * mt * t * t * c2 + t * t * t * end
		)
	return points


# 実際につながっている橋の chunk のペア(橋のある側, 向こう側)一覧を返す。
func get_connected_chunk_pairs() -> Array:
	var result = []
	for entry in _iter_bridges():
		if entry["piece"].get_connected_pieces().is_empty():
			continue
		result.append([entry["chunk_hex"], entry["target_chunk_hex"]])
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
	_update_landing_hints()


# アクティブな chunk の周りに描いている隣の chunk の座標
func get_neighbor_hexes() -> Array[Hex]:
	return _neighbor_hexes.duplicate()


# 隣の chunk を描く位置（ずらし方は ChunkTopology.chunk_offset）
func _neighbor_position(active: Chunk, chunk_delta: Hex) -> Vector2:
	return active.hex_to_pixel(
		ChunkTopology.chunk_offset(chunk_delta, active.grid_radius, gap_steps)
	)


# 隣どうしの chunk の中心の距離（画面上のピクセル）。ワールドマップとの縮尺合わせに使う
# chunk の見た目の大きさ（中心から辺までの距離）。外周のマスが作るギザギザの辺の、
# 頂点とくぼみの真ん中（マスの画像の頂点までの 3/4）を辺とみなす
func get_chunk_inradius() -> float:
	var active = get_active_chunk()
	var radius = active.grid_radius if active else 5
	var cell_spacing = Layout.hex_to_pixel(Layout.make_default(), Hex.direction(0)).length()
	return radius * cell_spacing * sqrt(3.0) * 0.5 + HexTile.visual_circumradius() * 0.75


func get_chunk_spacing() -> float:
	var active = get_active_chunk()
	var radius = active.grid_radius if active else 5
	var layout = Layout.make_default()
	return (
		Layout
		. hex_to_pixel(layout, ChunkTopology.chunk_offset(Hex.direction(0), radius, gap_steps))
		. length()
	)


# 描いている chunk のうち、画面上の位置 pos に中心がいちばん近いもの
func get_nearest_visible_chunk(pos: Vector2):
	var nearest = null
	var best := INF
	for chunk_hex in _visible_chunk_hexes():
		var distance = pos.distance_to(get_chunk(chunk_hex).position)
		if distance < best:
			best = distance
			nearest = chunk_hex
	return nearest


# 画面上の位置（World の座標）にある施設。アクティブな chunk と、周りに描いている隣の chunk を探す
func get_piece_at_position(pos: Vector2) -> Piece:
	for chunk_hex in _visible_chunk_hexes():
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


# 描いている chunk で、橋の着地点（向かいのマスで空いているところ）を光らせる
func _update_landing_hints():
	for chunk_hex in _visible_chunk_hexes():
		get_chunk(chunk_hex).show_landing_hints(get_bridge_landing_hexes(chunk_hex))


# ローカル画面に描いている chunk（アクティブと、その周りの隣）
func _visible_chunk_hexes() -> Array[Hex]:
	var hexes: Array[Hex] = []
	if _active_hex != null:
		hexes.append(_active_hex)
	hexes.append_array(_neighbor_hexes)
	return hexes
