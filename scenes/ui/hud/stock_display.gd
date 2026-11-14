class_name StockDisplay
extends VBoxContainer

## ハブの在庫（HubGoals.stock）の表示。アイテムごとに「アイコン ×個数」を1行ずつ並べる。
## 設置や研究で在庫を消費したときは、その行に「-15」のように減った数をしばらく表示する。

# 減った数を表示しておく時間（秒）。終わりに向けて薄くなる
const DELTA_SECONDS := 1.6
const ICON_SIZE := Vector2(22, 22)
const EMPTY_TEXT := "在庫: なし"
const TITLE_TEXT := "在庫"
const DELTA_COLOR := Color(1.0, 0.5, 0.45)

var _title: Label
var _rows: Dictionary = {}  # item_id → {row, icon, count, delta}
var _previous: Dictionary = {}  # 前回見たときの在庫 {item_id: 個数}
var _pending_delta: Dictionary = {}  # 表示中の減った数 {item_id: 個数}
var _delta_time_left: Dictionary = {}  # {item_id: 残り秒数}


func _ready() -> void:
	add_theme_constant_override("separation", 2)
	_title = Label.new()
	_title.add_theme_font_size_override("font_size", 14)
	add_child(_title)
	HubGoals.stock_changed.connect(_on_stock_changed)
	_previous = HubGoals.stock.duplicate()
	_refresh()


func _process(delta: float) -> void:
	if _delta_time_left.is_empty():
		return
	for item_id in _delta_time_left.keys():
		_delta_time_left[item_id] -= delta
		if _delta_time_left[item_id] <= 0.0:
			_delta_time_left.erase(item_id)
			_pending_delta.erase(item_id)
	_refresh()


# 表示しているアイテムの id（上から順）
func get_item_ids() -> Array:
	return _rows.keys()


func get_count_text(item_id: String) -> String:
	return _rows[item_id]["count"].text if _rows.has(item_id) else ""


func get_icon(item_id: String) -> Texture2D:
	return _rows[item_id]["icon"].texture if _rows.has(item_id) else null


# 表示中の減った数（例: "-15"）。表示していなければ空文字
func get_delta_text(item_id: String) -> String:
	if not _rows.has(item_id) or not _rows[item_id]["delta"].visible:
		return ""
	return _rows[item_id]["delta"].text


# 在庫の中身を1行の文章にしたもの（動作確認の出力用）
func get_summary_text() -> String:
	if _rows.is_empty():
		return EMPTY_TEXT
	var parts: Array[String] = []
	for item_id in _rows:
		parts.append("%s %s" % [_item_name(item_id), get_count_text(item_id)])
	return "在庫: " + "、".join(parts)


func _on_stock_changed() -> void:
	for item_id in _previous:
		var decreased = _previous[item_id] - HubGoals.get_stock(item_id)
		# やり直し（リセット）で在庫が丸ごと消えたときは、消費ではないので出さない
		if decreased > 0 and not HubGoals.stock.is_empty():
			_pending_delta[item_id] = _pending_delta.get(item_id, 0) + decreased
			_delta_time_left[item_id] = DELTA_SECONDS
	if HubGoals.stock.is_empty():
		_pending_delta.clear()
		_delta_time_left.clear()
	_previous = HubGoals.stock.duplicate()
	_refresh()


func _refresh() -> void:
	# 在庫があるか、減った数を表示中のアイテムを並べる
	var visible_ids := []
	for item_id in HubGoals.stock:
		if HubGoals.get_stock(item_id) > 0 or _pending_delta.has(item_id):
			visible_ids.append(item_id)
	for item_id in _rows.keys():
		if not item_id in visible_ids:
			_rows[item_id]["row"].free()
			_rows.erase(item_id)
	for item_id in visible_ids:
		if not _rows.has(item_id):
			_rows[item_id] = _build_row(item_id)
		_rows[item_id]["count"].text = "×%d" % HubGoals.get_stock(item_id)
		_refresh_delta(item_id)
	_title.text = EMPTY_TEXT if _rows.is_empty() else TITLE_TEXT


func _refresh_delta(item_id: String) -> void:
	var label: Label = _rows[item_id]["delta"]
	label.visible = _pending_delta.has(item_id)
	if label.visible:
		label.text = "-%d" % _pending_delta[item_id]
		label.modulate.a = clampf(_delta_time_left[item_id] / DELTA_SECONDS * 2.0, 0.0, 1.0)


func _build_row(item_id: String) -> Dictionary:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	add_child(row)
	var icon := TextureRect.new()
	var item = ItemDB.get_item(item_id)
	icon.texture = item.icon if item else null
	icon.custom_minimum_size = ICON_SIZE
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.tooltip_text = _item_name(item_id)
	row.add_child(icon)
	var count := Label.new()
	count.add_theme_font_size_override("font_size", 15)
	row.add_child(count)
	var delta := Label.new()
	delta.add_theme_font_size_override("font_size", 15)
	delta.add_theme_color_override("font_color", DELTA_COLOR)
	delta.visible = false
	row.add_child(delta)
	return {"row": row, "icon": icon, "count": count, "delta": delta}


func _item_name(item_id: String) -> String:
	var item = ItemDB.get_item(item_id)
	return item.display_name if item else item_id
