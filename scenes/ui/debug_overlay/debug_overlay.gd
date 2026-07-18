class_name DebugOverlay
extends CanvasLayer

const _LABEL_SIZE := Vector2(84, 40)

var _chunk = null


func _ready():
	visible = false
	follow_viewport_enabled = true


func toggle() -> void:
	visible = not visible


func refresh(chunk) -> void:
	_chunk = chunk
	_clear_labels()
	for hex in chunk.get_all_hexes():
		var label := Label.new()
		label.name = "hex_%d_%d" % [hex.q, hex.r]
		label.size = _LABEL_SIZE
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.position = chunk.hex_to_pixel(hex) - _LABEL_SIZE / 2
		add_child(label)
	_update_labels()


# ワールドマップ用: 各チャンクタイルの位置に座標ラベルを表示する
func refresh_world_map(view, chunk_hexes) -> void:
	_chunk = null
	_clear_labels()
	for hex in chunk_hexes:
		var label := Label.new()
		label.size = _LABEL_SIZE
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.position = view.position + view.get_tile_position(hex) - _LABEL_SIZE / 2
		label.text = "%d, %d" % [hex.q, hex.r]
		add_child(label)


# queue_free は遅延解放のため、切替直後の二重表示・ラベル数の混在を防ぐ目的で即時に外す
func _clear_labels() -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()


func _process(_delta: float) -> void:
	if not visible or _chunk == null:
		return
	_update_labels()


func _update_labels() -> void:
	for hex in _chunk.get_all_hexes():
		var node = get_node_or_null("hex_%d_%d" % [hex.q, hex.r])
		if node == null:
			continue
		var piece = _chunk.get_piece_at_hex(hex)
		if piece:
			node.text = "%d, %d\n%s" % [hex.q, hex.r, piece.piece_name]
		else:
			node.text = "%d, %d" % [hex.q, hex.r]


func get_label_count() -> int:
	return get_child_count()


func get_label_text_at(hex: Hex) -> String:
	var node = get_node_or_null("hex_%d_%d" % [hex.q, hex.r])
	return node.text if node else ""
