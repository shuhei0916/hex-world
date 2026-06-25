class_name DebugOverlay
extends CanvasLayer


func _ready():
	visible = false


func toggle() -> void:
	visible = not visible


func refresh(_chunk) -> void:
	pass
