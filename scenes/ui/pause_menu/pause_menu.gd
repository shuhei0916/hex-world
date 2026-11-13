class_name PauseMenu
extends CanvasLayer

## ESC で開閉するポーズメニュー。開いている間はゲームを一時停止する。
## 一時停止中も入力を受け付けるよう process_mode は ALWAYS（シーン側で設定）。
## 終了はテストで実際に終了しないよう、シグナルで Main に任せる。

signal quit_requested

@onready var resume_button: Button = %ResumeButton
@onready var quit_button: Button = %QuitButton


func _ready() -> void:
	visible = false
	resume_button.pressed.connect(close)
	quit_button.pressed.connect(func(): quit_requested.emit())


func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.is_echo()):
		return
	if event.keycode != KEY_ESCAPE:
		return
	if visible:
		close()
	else:
		open()
	var viewport = get_viewport()
	if viewport:
		viewport.set_input_as_handled()


func open() -> void:
	visible = true
	get_tree().paused = true
	resume_button.grab_focus()


func close() -> void:
	visible = false
	get_tree().paused = false
