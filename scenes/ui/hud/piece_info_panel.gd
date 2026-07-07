class_name PieceInfoPanel
extends PanelContainer

@onready var name_label: Label = $VBoxContainer/NameLabel
@onready var description_label: Label = $VBoxContainer/DescriptionLabel
@onready var rate_label: Label = $VBoxContainer/RateLabel
@onready var variant_row: HBoxContainer = $VBoxContainer/VariantRow


func show_info(piece_name: String, piece_description: String, rate_text: String = "") -> void:
	name_label.text = piece_name
	description_label.text = piece_description
	rate_label.text = rate_text
	rate_label.visible = not rate_text.is_empty()
	visible = true


func show_variants(labels: Array[String], active_index: int, on_pressed: Callable) -> void:
	for child in variant_row.get_children():
		child.queue_free()
	for i in labels.size():
		var btn := Button.new()
		btn.text = labels[i]
		btn.toggle_mode = true
		btn.button_pressed = (i == active_index)
		var vi := i
		btn.pressed.connect(func(): on_pressed.call(vi))
		variant_row.add_child(btn)
	variant_row.visible = true


func hide_variants() -> void:
	variant_row.visible = false


func clear() -> void:
	hide_variants()
	visible = false
