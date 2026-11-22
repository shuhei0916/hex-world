@tool
class_name Piece
extends Node2D

signal recipe_changed(recipe: Recipe)
signal shape_changed

const FORWARD_TEXTURE = preload("res://scenes/components/piece/forward.png")
const PORT_OFFSET = 35.0
const ARROW_COLOR = Color(0.9607843, 0.6509804, 0.13725491, 1)
const CONNECTED_COLOR = Color(0.5, 1.0, 0.5, 1)
## 本体を描く高さ（地面のマスは 0）
const BODY_Z_INDEX := 10

# シーンに保存されるピース定義データ（各 .tscn に直接設定する）
@export var piece_name: String = ""
@export_multiline var piece_description: String = ""
@export var piece_type: PieceData.Type = PieceData.Type.CONVEYOR
@export var piece_shape: Array[Vector2i] = []
@export var port_hex: Vector2i = Vector2i.ZERO
@export var port_hex2: Vector2i = Vector2i.ZERO
@export var port_direction: int = -1  # -1 = 出力ポートなし
@export var port_direction2: int = -1  # -1 = 第2出力なし
@export var piece_color: Color

# 回転状態 (0-5)
var rotation_state: int = 0
# コンベアがどちら側(0-5)から受け取るか。-1 は未指定（出力の反対側から受け取る直進）
var input_direction: int = -1

# プロパティアクセサ
var current_recipe: Recipe:
	get:
		return crafter.current_recipe if crafter else null

var _output_arrow: Sprite2D = null
var _output_arrow2: Sprite2D = null
var _connection_direction: int = -1

# 部品。ピースの種類ごとに、シーンにこの名前で子として置く（無いものは null）。
# 型の合わない部品が付いていたら、黙って無視せず読み込み時にエラーになる
@onready var ejector: ItemEjector = get_node_or_null("ItemEjector")
@onready var crafter: Crafter = get_node_or_null("Crafter")
@onready var conveyor_logic: ConveyorLogic = get_node_or_null("ConveyorLogic")
@onready var chest_input: ChestInput = get_node_or_null("ChestInput")
@onready var chest_output: ChestOutput = get_node_or_null("ChestOutput")
@onready var hub: Hub = get_node_or_null("Hub")


func _ready():
	if Engine.is_editor_hint():
		_refresh_output_arrow()
		_create_hex_tiles()
		return
	if crafter and ejector:
		crafter.setup(ejector)


func _process(delta: float):
	if Engine.is_editor_hint():
		return
	tick(delta)


# 占めるマスを合わせた1つの形の本体（PieceBody）を描き直す。
# 地面のマスより内側に縮めて描くので、下の床や鉱床が縁からのぞく。
func _create_hex_tiles():
	var old_body := get_node_or_null("Body")
	if old_body:
		remove_child(old_body)
		old_body.queue_free()
	if piece_shape.is_empty():
		return
	# ベルトを描くコンベアは画像自体が見た目を担うので本体は描かない。
	if is_conveyor():
		return
	var body := PieceBody.new()
	body.name = "Body"
	body.z_index = BODY_Z_INDEX
	body.z_as_relative = false
	add_child(body)
	body.setup(get_hex_shape(), piece_color)
	_refresh_body_icon()
	_refresh_connection_indicator()


# 本体の中央に、作っている品物のアイコンを出す（レシピを持たない設置物は出さない）
func _refresh_body_icon() -> void:
	var body := get_node_or_null("Body")
	if not body:
		return
	var recipe := current_recipe
	var item = null
	if recipe and not recipe.outputs.is_empty():
		item = ItemDB.get_item(recipe.outputs.keys()[0])
	body.set_icon(item.icon if item else null)


func setup(rotation: int = 0):
	if crafter:
		crafter.set_recipe(null)
	rotation_state = rotation
	var recipes = Recipe.RecipeDB.get_recipes_by_type(piece_type)
	if crafter:
		crafter.set_available_recipes(recipes)
		crafter.is_miner = piece_type == PieceData.Type.MINER
	if not recipes.is_empty():
		set_recipe(recipes[0])
	_ensure_port_visuals()
	_refresh_output_arrow()
	_create_hex_tiles()
	shape_changed.emit()


# 施設（ベルト以外）には、出入口を描く PortVisuals を付ける
func _ensure_port_visuals() -> void:
	if Engine.is_editor_hint() or is_conveyor() or has_node("PortVisuals"):
		return
	var ports := PortVisuals.new()
	ports.name = "PortVisuals"
	add_child(ports)


func set_recipe(recipe: Recipe):
	if crafter:
		crafter.set_recipe(recipe)
	_refresh_body_icon()
	recipe_changed.emit(recipe)


# 鉱床の濃さ（加工の速さの倍率）
func set_speed_multiplier(n: int):
	if crafter:
		crafter.speed_multiplier = n


func add_item(item_name: String, amount: int):
	var acc = get_acceptor()
	if acc:
		acc.add_item(item_name, amount)


# 手元にある item_name の数（加工待ちの材料・ベルトの上・排出待ちの合計）
func get_item_count(item_name: String) -> int:
	var count := 0
	if crafter:
		count += crafter.get_item_count(item_name)
	if conveyor_logic:
		count += conveyor_logic.get_item_count(item_name)
	if ejector:
		count += ejector.get_item_count(item_name)
	return count


func tick(delta: float):
	# 全 tick を Piece に集約する。生産 → 搬送・排出 → 倉庫からの次の取り出し の順に進めるので、
	# 同じフレームのうちに「作る → 出す」が流れる（部品が自分で _process を回す二重 tick も避ける）
	if crafter:
		crafter.tick(delta)
	if conveyor_logic:
		conveyor_logic.tick(delta)
	if ejector:
		ejector.tick(delta)
	if chest_output:
		chest_output.tick(delta)


func get_hex_shape() -> Array[Vector2i]:
	var hexes: Array[Vector2i] = []
	for v in piece_shape:
		hexes.append(Hex.from_offset_rotated(v, rotation_state))
	return hexes


func set_rotation_state(rotation: int) -> void:
	rotation_state = rotation
	_refresh_output_arrow()
	_create_hex_tiles()
	shape_changed.emit()


func get_output_ports() -> Array:
	var ports = []
	if port_direction >= 0:
		ports.append(_make_port(port_hex, port_direction))
	if port_direction2 >= 0:
		ports.append(_make_port(port_hex2, port_direction2))
	return ports


func _make_port(offset: Vector2i, direction: int) -> Dictionary:
	var hex = Hex.from_offset_rotated(offset, rotation_state)
	var rotated_direction = (direction - rotation_state + 6) % 6
	return {"hex": hex, "direction": rotated_direction}


# コンベアか。種類で決める（見た目の部品の有無では判断しない）。
# 橋もベルトと同じ動きの部品（ConveyorLogic）を持つが、コンベアではない
func is_conveyor() -> bool:
	return piece_type == PieceData.Type.CONVEYOR


func _refresh_output_arrow():
	if _output_arrow:
		_output_arrow.queue_free()
		_output_arrow = null
	if _output_arrow2:
		_output_arrow2.queue_free()
		_output_arrow2 = null
	# ベルト画像自体が方向を示すので、コンベアには矢印を出さない。
	if is_conveyor():
		return
	var ports = get_output_ports()
	if ports.is_empty():
		return
	_output_arrow = make_output_arrow(ports[0])
	add_child(_output_arrow)
	if ports.size() > 1:
		_output_arrow2 = make_output_arrow(ports[1])
		add_child(_output_arrow2)
	# 出入口を PortVisuals が描く施設では、従来の矢印は重なるので隠す
	if has_node("PortVisuals"):
		_output_arrow.visible = false
		if _output_arrow2:
			_output_arrow2.visible = false


# アイテムの受け入れ口になる部品（shapez の ItemAcceptor 相当）。受け入れないピースは null。
# どれも can_accept_item(item_name) と add_item(item_name, amount) を持つ
func get_acceptor() -> Node:
	if conveyor_logic:
		return conveyor_logic
	if crafter:
		return crafter
	if chest_input:
		return chest_input
	if hub:
		return hub
	return null


func can_accept_item(item_name: String) -> bool:
	var acc = get_acceptor()
	return acc != null and acc.can_accept_item(item_name)


# 送り出す先のピースを、送り出す部品（ベルトの動き か 排出口）に伝える
func set_connected_pieces(pieces: Array, directions: Array = []) -> void:
	var sender = _sender()
	if sender:
		sender.set_connected_pieces(pieces, directions)
	_connection_direction = directions[0] if not directions.is_empty() else -1
	_refresh_connection_indicator()


func get_connected_pieces() -> Array:
	var sender = _sender()
	return sender.get_connected_pieces() if sender else []


func _sender() -> Node:
	if conveyor_logic:
		return conveyor_logic
	return ejector


# 共有倉庫を使う部品（チェスト）。無ければ null
func get_chest() -> Node:
	return chest_input if chest_input else chest_output


# ベルトを、入ってくる側（先頭が主入力）から出ていく側へ描き直す。ベルトを描かないピースでは何もしない
func show_belt_directions(input_directions: Array, output_directions: Array) -> void:
	var visuals := get_node_or_null("ConveyorVisuals") as ConveyorVisuals
	if visuals:
		visuals.set_input_directions(input_directions)
		visuals.set_output_directions(output_directions)


# chunk から撤去されるとき。手元にアイテムを持つ部品に片付ける機会を与える
func on_removed() -> void:
	if chest_output:
		chest_output.on_piece_removed()


func has_connected_piece() -> bool:
	return not get_connected_pieces().is_empty()


func _refresh_connection_indicator() -> void:
	if piece_type != PieceData.Type.BRIDGE:
		return
	# つながっている橋は本体を緑がかった色にする。向きは溝の上の帯（BridgeOverlay）で示す。
	# modulate は子にも伝播するため、本体だけを個別に着色する。
	var body := get_node_or_null("Body")
	if body:
		body.modulate = CONNECTED_COLOR if has_connected_piece() else Color(1, 1, 1)


static func make_output_arrow(port: Dictionary) -> Sprite2D:
	var layout = Layout.make_default()
	var center_pos = Layout.hex_to_pixel(layout, port["hex"])
	var neighbor_pos = Layout.hex_to_pixel(layout, Hex.neighbor(port["hex"], port["direction"]))
	var angle = (neighbor_pos - center_pos).angle()
	var arrow = Sprite2D.new()
	arrow.texture = FORWARD_TEXTURE
	arrow.scale = Vector2(0.5, 0.5)
	arrow.modulate = ARROW_COLOR
	arrow.position = center_pos + Vector2(PORT_OFFSET, 0).rotated(angle)
	arrow.rotation = angle
	return arrow
