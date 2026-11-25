# gdlint:disable=max-public-methods
class_name World
extends Node2D

# 1 chunk あたりの鉱床のマス数
const DEPOSIT_SIZE := 5
# ローカル画面で、アクティブな chunk の周りに描く隣の chunk は、操作できないので薄めて描く。
# 色は配色の neighbor_modulate（所有している隣）と unowned_modulate（所有していない隣）。
# 暗くしすぎると床のタイルが背景に溶けて見えなくなる
# キャラクターが壁に当たったとき、押した向きから何度傾けた向きへ滑るかを試す（近い順）
const SLIDE_ANGLES := [30.0, 60.0]
# 橋の帯の曲線を何本の線分で描くか
const BRIDGE_PATH_SEGMENTS := 16

# 隣の chunk との間の溝の幅。辺に垂直な斜め方向に何段ずらすか（1段 ≒ タイル0.7個分、
# 2段 ≒ 2.5個分、3段 ≒ 4.2個分）。境界がひと目で分かるようにする
static var gap_steps := 2

# planet チェストが共有する、惑星全体で1つの倉庫
var planet_storage := SharedStorage.new()
# どの chunk を所有しているか。入って工場を作れるのは所有している chunk だけ
var territory := Territory.new()
# プレイヤーキャラクター。place_player するまでは null
var player: PlayerCharacter = null
# false の間はキャラクターを描かない（戦闘中は戦闘の主人公として描かれる）
var player_shown := true:
	set(value):
		player_shown = value
		_update_player_view()

var _chunks: Dictionary = {}
var _chunk_hexes: Array[Vector2i] = []  # 生成済み chunk の座標
var _active_hex = null
var _neighbor_hexes: Array[Vector2i] = []  # アクティブな chunk の周りに描いている chunk
var _planet: Planet = null
# バイオームチェストが共有する倉庫。地域（Planet の region）ごとに1つ {地域番号: SharedStorage}
var _region_storages: Dictionary = {}
var _player_view := PlayerView.new()


func _ready() -> void:
	var overlay := BridgeOverlay.new()
	overlay.name = "BridgeOverlay"
	add_child(overlay)
	_player_view.visible = false
	add_child(_player_view)
	territory.changed.connect(_on_territory_changed)


# プレイヤーキャラクターを chunk_hex の chunk の hex のマスに立たせる
func place_player(chunk_hex: Vector2i, hex: Vector2i) -> void:
	player = PlayerCharacter.new(chunk_hex, hex)
	_update_player_view()


# キャラクターを、立っている chunk の中の位置 pos へそのまま置く（セーブからの復元用）
func move_player_to(pos: Vector2) -> void:
	player.position = pos
	_update_player_view()


# キャラクターを motion（chunk の中のピクセル）だけ動かす。動けたら true。
# 通れないマスや chunk の外にかかる位置へは入らない。壁に当たったら、押した向きを少しずつ傾けた
# 向き（傾けた分だけ短くする）や、横だけ・縦だけの動きを試して、壁に沿って滑る。
# マスの辺は斜め（30度・90度・150度）なので、横・縦だけでなく30度・60度ずつ傾けた向きも試す
func move_player_by(motion: Vector2) -> bool:
	if player == null or motion == Vector2.ZERO:
		return false
	var chunk: Chunk = get_chunk(player.chunk_hex)
	var steps: Array[Vector2] = [motion]
	for degrees in SLIDE_ANGLES:
		var angle = deg_to_rad(degrees)
		for sign in [1.0, -1.0]:
			steps.append(motion.rotated(angle * sign) * cos(angle))
	steps.append_array([Vector2(motion.x, 0), Vector2(0, motion.y)])
	for step in steps:
		if step != Vector2.ZERO and PlayerCharacter.can_stand_at(chunk, player.position + step):
			player.position += step
			_update_player_view()
			return true
	return false


# chunk_hex の chunk の hexes に上を歩けないピースを置く前に、そこに重なるキャラクターを
# いちばん近い立てる位置へ押し出す。押し出す必要が無いか、押し出せたら true。
# 押し出せる場所が無ければ false（キャラクターは動かさない）
func push_player_out_of(chunk_hex: Vector2i, hexes: Array) -> bool:
	if player == null or player.chunk_hex != chunk_hex:
		return true
	var pushed = PlayerCharacter.push_out_position(get_chunk(chunk_hex), player.position, hexes)
	if pushed == null:
		return false
	move_player_to(pushed)
	return true


# キャラクターが今のマスから渡れる先 {chunk_hex, hex}。辺のマスに立っていれば、その辺の向こうの
# chunk の向かい合うマス。内側のマスや角（2つの辺にまたがる）、惑星の外へは渡れないので空
func get_player_crossing() -> Dictionary:
	if player == null:
		return {}
	var edge_dir = get_chunk(player.chunk_hex).get_edge_direction(player.hex)
	if edge_dir == -1:
		return {}
	var target = Hex.neighbor(player.chunk_hex, ChunkTopology.to_world_direction(edge_dir))
	if _planet and not _planet.has_chunk(target):
		return {}
	return {"chunk_hex": target, "hex": ChunkTopology.mirror_hex(player.hex, edge_dir)}


# キャラクターを、辺の向こうの chunk の向かい合うマスへ渡らせる。渡れたら true。
# 向かいのマスが通れなければ渡らない（所有しているかどうかは呼び出し側で確かめる）
func cross_player() -> bool:
	var crossing = get_player_crossing()
	if crossing.is_empty():
		return false
	var target_chunk = get_chunk(crossing["chunk_hex"])
	if target_chunk == null:
		target_chunk = create_chunk(crossing["chunk_hex"])
	if not PlayerCharacter.can_enter(target_chunk, crossing["hex"]):
		return false
	place_player(crossing["chunk_hex"], crossing["hex"])
	return true


# キャラクターの立っているマスの中心の、画面上の位置（World の座標）
func get_player_position() -> Vector2:
	var chunk: Chunk = get_chunk(player.chunk_hex)
	return chunk.position + player.position


# キャラクターの上に出す操作の案内（空なら出さない）
func set_player_prompt(text: String) -> void:
	_player_view.set_prompt(text)


# キャラクターを、立っている chunk の描かれている位置に合わせて描く。描かれていなければ隠す
func _update_player_view() -> void:
	if not player_shown or player == null or not _visible_chunk_hexes().has(player.chunk_hex):
		_player_view.visible = false
		return
	_player_view.jump_to(get_player_position())
	_player_view.visible = true


# planet を設定する。chunk の実体は初めてアクティブにしたときに生成する（遅延生成）。
func setup_planet(planet: Planet) -> void:
	_planet = planet
	territory.planet = planet


func get_planet() -> Planet:
	return _planet


# generate_deposits=false はセーブデータからの復元用（鉱床は保存された配置を使う）
func create_chunk(chunk_hex: Vector2i, generate_deposits: bool = true) -> Chunk:
	var key = chunk_hex
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
func _resolve_storage(scope: String, chunk_hex: Vector2i) -> SharedStorage:
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


func _generate_biome_deposits(chunk_hex: Vector2i, chunk: Chunk) -> void:
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
func get_bridge_landing_hexes(chunk_hex: Vector2i) -> Array:
	var result = []
	var chunk = get_chunk(chunk_hex)
	if chunk == null:
		return result
	for entry in _iter_bridges():
		if entry["target_chunk_hex"] != chunk_hex:
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
		visible_keys[chunk_hex] = true
	var spans = []
	for entry in _iter_bridges():
		if not visible_keys.has(entry["chunk_hex"]):
			continue
		if not visible_keys.has(entry["target_chunk_hex"]):
			continue
		var target_chunk = get_chunk(entry["target_chunk_hex"])
		var piece: Piece = entry["piece"]
		var logic := piece.conveyor_logic
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


# ワールドマップに出す chunk から chunk への輸送。つながっている橋を「どこから・どこへ」ごとに
# まとめ、渡した品目ごとの 個/分 を足し合わせる。まだ何も渡していない輸送路も items を空で返す。
# 各要素: {from: 橋のある chunk, to: 向こうの chunk, items: {品目: 個/分}}
func get_chunk_transfers() -> Array:
	var by_route := {}
	var result = []
	for entry in _iter_bridges():
		var piece: Piece = entry["piece"]
		if not piece.has_connected_piece():
			continue
		var route = [entry["chunk_hex"], entry["target_chunk_hex"]]
		if not by_route.has(route):
			by_route[route] = {"from": route[0], "to": route[1], "items": {}}
			result.append(by_route[route])
		var items: Dictionary = by_route[route]["items"]
		var rates = piece.conveyor_logic.get_items_per_minute()
		for item_name in rates:
			items[item_name] = items.get(item_name, 0.0) + rates[item_name]
	return result


func get_chunk_hexes() -> Array[Vector2i]:
	return _chunk_hexes.duplicate()


# ワールドマップに並べる chunk の座標。planet があれば未生成の chunk も含む。
func get_map_hexes() -> Array[Vector2i]:
	if _planet:
		return _planet.get_chunk_hexes()
	return get_chunk_hexes()


func get_chunk(chunk_hex: Vector2i):
	return _chunks.get(chunk_hex, null)


func get_active_hex():
	return _active_hex


func get_active_chunk() -> Chunk:
	if _active_hex == null:
		return null
	return get_chunk(_active_hex)


func set_active_chunk(chunk_hex: Vector2i):
	if _planet and not _planet.has_chunk(chunk_hex):
		return
	if get_chunk(chunk_hex) == null:
		create_chunk(chunk_hex)
	_active_hex = chunk_hex
	_layout_visible_chunks()
	_update_landing_hints()


# アクティブな chunk の周りに描いている隣の chunk の座標
func get_neighbor_hexes() -> Array[Vector2i]:
	return _neighbor_hexes.duplicate()


# 隣の chunk を描く位置（ずらし方は ChunkTopology.chunk_offset）
func _neighbor_position(active: Chunk, chunk_delta: Vector2i) -> Vector2:
	return active.hex_to_pixel(
		ChunkTopology.chunk_offset(chunk_delta, active.grid_radius, gap_steps)
	)


# 隣どうしの chunk の中心の距離（画面上のピクセル）。ワールドマップとの縮尺合わせに使う
func get_chunk_spacing() -> float:
	var active = get_active_chunk()
	var radius = active.grid_radius if active else Chunk.DEFAULT_RADIUS
	var layout = Layout.make_default()
	return (
		Layout
		. hex_to_pixel(layout, ChunkTopology.chunk_offset(Hex.direction(0), radius, gap_steps))
		. length()
	)


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
		chunk.position = _neighbor_position(active, hex - _active_hex)
		chunk.modulate = ColorTheme.color(
			&"neighbor_modulate" if territory.is_owned(hex) else &"unowned_modulate"
		)
	_update_player_view()


# 配色を切り替えたとき、隣の chunk の薄め方を新しい配色で塗り直す
func apply_color_theme() -> void:
	if _active_hex != null:
		_layout_visible_chunks()


# 解放した隣の chunk を明るく描き直す
func _on_territory_changed() -> void:
	if _active_hex != null:
		_layout_visible_chunks()


# 描いている chunk で、橋の着地点（向かいのマスで空いているところ）を光らせる
func _update_landing_hints():
	for chunk_hex in _visible_chunk_hexes():
		get_chunk(chunk_hex).show_landing_hints(get_bridge_landing_hexes(chunk_hex))


# ローカル画面に描いている chunk（アクティブと、その周りの隣）
func _visible_chunk_hexes() -> Array[Vector2i]:
	var hexes: Array[Vector2i] = []
	if _active_hex != null:
		hexes.append(_active_hex)
	hexes.append_array(_neighbor_hexes)
	return hexes
