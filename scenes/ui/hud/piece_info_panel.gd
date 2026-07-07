class_name PieceInfoPanel
extends PanelContainer

@onready var name_label: Label = $VBoxContainer/NameLabel
@onready var description_label: Label = $VBoxContainer/DescriptionLabel
@onready var rate_label: Label = $VBoxContainer/RateLabel


func show_info(piece_name: String, piece_description: String, rate_text: String = "") -> void:
	name_label.text = piece_name
	description_label.text = piece_description
	rate_label.text = rate_text
	rate_label.visible = not rate_text.is_empty()
	visible = true


func clear() -> void:
	visible = false
