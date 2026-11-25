class_name WorldMapView
extends Node2D

const ChunkTileScript = preload("res://scenes/components/world/chunk_tile.gd")
const TILE_SIZE := 80.0

const INFO_LABEL_SIZE := Vector2(120, 48)
# 往復する輸送路のカードを、それぞれ進む向きの右側へずらす量（重ならないようにカードの幅より少し大きく）
const LANE_OFFSET := TransferCard.WIDTH * 0.5 + 4.0
# 表示中に World から輸送を読み直す間隔（秒）
const REFRESH_INTERVAL := 1.0
# 描く順: タイル(0) < 輸送のカード < ホバーの情報
const TRANSFER_CARD_Z := 1
const INFO_LABEL_Z := 2
# まだ所有していない chunk の色。所有している chunk の隣（戦って解放できる）はバイオーム色を
# 沈めて（ダークは暗く、ライトは霧の色に寄せて）何が採れるかを見せ、それより遠くは霧（配色の fog）で隠す
const FRONTIER_DARKEN := 0.55
const FOG_TEXT := "未踏"
const CHALLENGE_TEXT := "戦って解放"

var _tiles: Dictionary = {}  # chunk の座標 → ChunkTile
var _active_hex = null
var _hovered_hex = null
var _map_layout: Layout
var _transfer_cards: Array[TransferCard] = []
var _refresh_timer := 0.0
var _planet: Planet = null
var _world: World = null
var _info_label: Label = null


func _init() -> void:
	_map_layout = Layout.new(Layout.layout_flat, Vector2(TILE_SIZE, TILE_SIZE), Vector2.ZERO)


func setup(world: World) -> void:
	for child in get_children():
		child.queue_free()
	_tiles.clear()
	_transfer_cards.clear()
	_active_hex = null
	_hovered_hex = null
	_world = world
	_planet = world.get_planet()

	# ワールドマップは地続きの大地として見せるので、タイルは隣と隙間なく接する大きさにする
	# （ローカル画面の chunk 間の溝はここには持ち込まない）
	var tile_inradius = get_tile_spacing() * 0.5
	for hex in world.get_map_hexes():
		var tile = ChunkTileScript.new()
		tile.setup(hex, _tile_color(hex))
		tile.set_inradius(tile_inradius)
		tile.position = Layout.hex_to_pixel(_map_layout, hex)
		add_child(tile)
		_tiles[hex] = tile

	_info_label = Label.new()
	_info_label.size = INFO_LABEL_SIZE
	_info_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_info_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_info_label.z_index = INFO_LABEL_Z  # 隣のタイルや輸送のカードより手前に出す
	_info_label.visible = false
	add_child(_info_label)


func _tile_color(hex: Vector2i) -> Color:
	var biome = _planet.get_biome(hex) if _planet else null
	if biome == null:
		return ChunkTileScript.NORMAL_COLOR
	var biome_color := ColorTheme.map_color(biome.map_color)
	if _world.territory.is_owned(hex):
		return biome_color
	if _world.territory.can_challenge(hex):
		return biome_color.lerp(ColorTheme.color(&"frontier_veil"), FRONTIER_DARKEN)
	return ColorTheme.color(&"fog")


# 配色を切り替えたとき、タイルを新しい配色の色で塗り直す
func apply_color_theme() -> void:
	for hex in _tiles:
		_tiles[hex].setup(hex, _tile_color(hex))


# 霧に隠れている chunk（所有しておらず、所有している chunk の隣でもない）
func _is_fogged(hex: Vector2i) -> bool:
	return (
		_planet != null
		and not _world.territory.is_owned(hex)
		and not _world.territory.can_challenge(hex)
	)


func set_active_chunk(chunk_hex: Vector2i) -> void:
	if _active_hex != null:
		var prev = _tiles.get(_active_hex)
		if prev:
			prev.set_active(false)
	_active_hex = chunk_hex
	var tile = _tiles.get(chunk_hex)
	if tile:
		tile.set_active(true)


func set_hovered_chunk(chunk_hex) -> void:
	if _hovered_hex != null:
		var prev = _tiles.get(_hovered_hex)
		if prev:
			prev.set_hovered(false)
	_hovered_hex = chunk_hex
	_update_info_label()
	if chunk_hex == null:
		return
	var tile = _tiles.get(chunk_hex)
	if tile:
		tile.set_hovered(true)


# ホバー中の chunk のバイオームと採れる資源をタイル上に表示する
func _update_info_label() -> void:
	if _info_label == null:
		return
	_info_label.text = _info_text(_hovered_hex)
	_info_label.visible = _info_label.text != ""
	if _info_label.visible:
		_info_label.position = get_tile_position(_hovered_hex) - INFO_LABEL_SIZE / 2


func _info_text(hex) -> String:
	var biome = _planet.get_biome(hex) if _planet and hex != null else null
	if biome == null:
		return ""
	if _is_fogged(hex):
		return FOG_TEXT
	var item = ItemDB.get_item(biome.resource_type)
	var resource_name = item.display_name if item else biome.resource_type
	var text = "%s\n%s" % [biome.display_name, resource_name]
	if _world.territory.can_challenge(hex):
		text += "\n" + CHALLENGE_TEXT
	return text


func get_hover_info_text() -> String:
	return _info_label.text if _info_label else ""


func get_tile_color(chunk_hex: Vector2i) -> Color:
	var tile = _tiles.get(chunk_hex)
	return tile.get_current_color() if tile else Color.TRANSPARENT


func get_tile_hovered(chunk_hex: Vector2i) -> bool:
	var tile = _tiles.get(chunk_hex)
	return tile.is_hovered if tile else false


func get_tile_count() -> int:
	return _tiles.size()


# 隣どうしのタイルの中心の距離。ローカル画面との縮尺合わせに使う
func get_tile_spacing() -> float:
	return Layout.hex_to_pixel(_map_layout, Hex.direction(0)).length()


func get_tile_inradius(chunk_hex: Vector2i) -> float:
	var tile = _tiles.get(chunk_hex)
	return tile.get_inradius() if tile else 0.0


func get_tile_position(chunk_hex: Vector2i) -> Vector2:
	var tile = _tiles.get(chunk_hex)
	return tile.position if tile else Vector2.ZERO


func get_tile_active(chunk_hex: Vector2i) -> bool:
	var tile = _tiles.get(chunk_hex)
	return tile.is_active if tile else false


func get_transfer_card_count() -> int:
	return _transfer_cards.size()


func get_transfer_card(index: int) -> TransferCard:
	return _transfer_cards[index]


# 工場はワールドマップ中も動き続けるので、表示中は輸送の数字を読み直す
func _process(delta: float) -> void:
	if not visible or _world == null:
		return
	_refresh_timer += delta
	if _refresh_timer >= REFRESH_INTERVAL:
		_refresh_timer = 0.0
		refresh_transfers(_world.get_chunk_transfers())


# 橋による輸送路（World.get_chunk_transfers の形）ごとに、2つのタイルの中間へカードを置く。
# 往復があれば、それぞれ進む向きの右側へずらす
func refresh_transfers(transfers: Array) -> void:
	for card in _transfer_cards:
		remove_child(card)
		card.queue_free()
	_transfer_cards.clear()
	var routes := {}
	for transfer in transfers:
		routes[[transfer["from"], transfer["to"]]] = true
	for transfer in transfers:
		var from_tile = _tiles.get(transfer["from"])
		var to_tile = _tiles.get(transfer["to"])
		if from_tile == null or to_tile == null:
			continue
		var direction = (to_tile.position - from_tile.position).normalized()
		var card := TransferCard.new()
		card.setup(direction, transfer["items"])
		card.position = (from_tile.position + to_tile.position) / 2.0
		if routes.has([transfer["to"], transfer["from"]]):
			# 画面は y が下向きなので、進む向きの右は orthogonal() の逆
			card.position -= direction.orthogonal() * LANE_OFFSET
		card.z_index = TRANSFER_CARD_Z
		add_child(card)
		_transfer_cards.append(card)


func chunk_at_local_pos(local_pos: Vector2):
	var hex = Layout.pixel_to_hex_rounded(_map_layout, local_pos)
	var key = hex
	if key in _tiles:
		return hex
	return null
