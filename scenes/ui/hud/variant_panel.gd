class_name VariantPanel
extends PanelContainer

@onready var button_row: HBoxContainer = $VBoxContainer/ButtonRow


func show_variants(labels: Array[String], active_index: int, on_pressed: Callable) -> void:
	for child in button_row.get_children():
		child.free()
	for i in labels.size():
		var btn := Button.new()
		btn.text = labels[i]
		btn.toggle_mode = true
		btn.button_pressed = (i == active_index)
		var vi := i
		btn.pressed.connect(func(): on_pressed.call(vi))
		button_row.add_child(btn)
	visible = true


func clear() -> void:
	visible = false
