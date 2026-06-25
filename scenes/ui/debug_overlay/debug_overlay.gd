class_name DebugOverlay
extends CanvasLayer


func _ready():
	visible = false


func toggle() -> void:
	visible = not visible


func refresh(chunk) -> void:
	for child in get_children():
		child.queue_free()
	for hex in chunk.get_all_hexes():
		var label := Label.new()
		label.name = "hex_%d_%d" % [hex.q, hex.r]
		var piece = chunk.get_piece_at_hex(hex)
		if piece:
			label.text = "%d,%d\n%s" % [hex.q, hex.r, piece.piece_name]
		else:
			label.text = "%d,%d" % [hex.q, hex.r]
		label.position = chunk.hex_to_pixel(hex)
		add_child(label)


func get_label_count() -> int:
	return get_child_count()


func get_label_text_at(hex: Hex) -> String:
	var node = get_node_or_null("hex_%d_%d" % [hex.q, hex.r])
	return node.text if node else ""
