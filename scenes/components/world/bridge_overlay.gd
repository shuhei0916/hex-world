class_name BridgeOverlay
extends Node2D

## 溝の上の橋の帯を描く。World の子に置き、World.get_bridge_spans() の帯を毎フレーム描く。
## 帯は橋の外側の辺の中点から、着地点の向かい合う辺の中点まで、辺に垂直に出入りする曲線で引く
## （着地点のコンベアの入口とそのままつながり、コンベアが溝を渡っているように見える）。
## - つながっている: コンベアと同じ色の帯に矢印を流し、渡している途中のアイテムを載せる
## - つながっていない: 半透明の帯（向かいのマスは World が着地点として光らせる）

# 地面(0)とコンベア(6)より手前、施設のタイル(10)より奥
const Z_INDEX := 8
const ITEM_Z_INDEX := 12
const BELT_WIDTH := ConveyorVisuals.BELT_WIDTH
const FILL_COLOR := Color(0.77, 0.77, 0.77, 1.0)
const EDGE_COLOR := Color(0.54, 0.54, 0.57, 1.0)
const ARROW_COLOR := Color(0.62, 0.62, 0.62, 1.0)
const UNCONNECTED_COLOR := Color(0.77, 0.77, 0.77, 0.3)
# 矢印の間隔。コンベア1マス（辺から辺まで）に2本と同じ密度にする
const ARROW_SPACING := 36.4
const ITEM_SIZE := Vector2(28, 28)

var _items := Node2D.new()

@onready var _world: World = get_parent()


func _ready() -> void:
	z_index = Z_INDEX
	z_as_relative = false
	_items.name = "Items"
	_items.z_index = ITEM_Z_INDEX
	_items.z_as_relative = false
	_items.draw.connect(_draw_items)
	add_child(_items)


func _process(_delta: float) -> void:
	queue_redraw()
	_items.queue_redraw()


func _draw() -> void:
	for span in _world.get_bridge_spans():
		var path: PackedVector2Array = span["path"]
		if span["connected"]:
			draw_polyline(path, EDGE_COLOR, BELT_WIDTH, true)
			draw_polyline(path, FILL_COLOR, BELT_WIDTH - 6.0, true)
			_draw_arrows(path)
		else:
			draw_polyline(path, UNCONNECTED_COLOR, BELT_WIDTH - 6.0, true)


# コンベアと同じ時計・同じ間隔で矢印を流す（橋の長さに応じて本数が増える）
func _draw_arrows(path: PackedVector2Array) -> void:
	var length := 0.0
	for i in range(path.size() - 1):
		length += path[i].distance_to(path[i + 1])
	if length < 1.0:
		return
	var phase = ConveyorVisuals.arrow_fractions(ConveyorVisuals.shared_clock())[0]
	var distance = fmod(phase * ARROW_SPACING * ConveyorVisuals.ARROWS_PER_PIECE, ARROW_SPACING)
	var fractions := []
	while distance < length:
		fractions.append(distance / length)
		distance += ARROW_SPACING
	for point in ConveyorVisuals.arrow_points(path, fractions):
		var shape = ConveyorVisuals.chevron_shape(point["position"], point["tangent"])
		draw_colored_polygon(shape, ARROW_COLOR)


# 渡している途中のアイテム。橋のマスの中心から帯をたどって着地点の辺まで進む
func _draw_items() -> void:
	for span in _world.get_bridge_spans():
		if span["item"] == "":
			continue
		var item = ItemDB.get_item(span["item"])
		if item == null or item.icon == null:
			continue
		var route := PackedVector2Array([span["from"]])
		route.append_array(span["path"])
		var points = ConveyorVisuals.arrow_points(route, [span["progress"]])
		if points.is_empty():
			continue
		var pos: Vector2 = points[0]["position"]
		_items.draw_texture_rect(item.icon, Rect2(pos - ITEM_SIZE * 0.5, ITEM_SIZE), false)
