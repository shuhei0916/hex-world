class_name PieceInfoPanel
extends PanelContainer

@onready var name_label: Label = $VBoxContainer/NameLabel
@onready var description_label: Label = $VBoxContainer/DescriptionLabel


func show_info(piece_name: String, piece_description: String) -> void:
	name_label.text = piece_name
	description_label.text = piece_description
	visible = true


func clear() -> void:
	visible = false
