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
		label.text = "%d,%d" % [hex.q, hex.r]
		label.position = chunk.hex_to_pixel(hex)
		add_child(label)


func get_label_count() -> int:
	return get_child_count()
