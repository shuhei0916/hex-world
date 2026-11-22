class_name VariantPanel
extends PanelContainer

@onready var button_row: HBoxContainer = $VBoxContainer/ButtonRow


# disabled: 押せないボタンの番号（未研究の切り替え先など）
func show_variants(
	labels: Array[String], active_index: int, on_pressed: Callable, disabled: Array = []
) -> void:
	# 押されたボタン自身のシグナルの中から作り直すことがあるので、すぐには解放しない（木から外して後で解放）
	for child in button_row.get_children():
		button_row.remove_child(child)
		child.queue_free()
	for i in labels.size():
		var btn := Button.new()
		btn.text = labels[i]
		btn.toggle_mode = true
		btn.button_pressed = (i == active_index)
		btn.disabled = i in disabled
		var vi := i
		btn.pressed.connect(func(): on_pressed.call(vi))
		button_row.add_child(btn)
	visible = true


func clear() -> void:
	visible = false
