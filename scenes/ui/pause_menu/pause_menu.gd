class_name PauseMenu
extends CanvasLayer

## ESC で開閉するポーズメニュー。開いている間はゲームを一時停止する。
## 一時停止中も入力を受け付けるよう process_mode は ALWAYS（シーン側で設定）。
## セーブ・やり直し・終了の実処理は、シグナルで Main に任せる（テストで実際に終了しないため）。

signal save_requested
signal new_game_requested
signal quit_requested

const NEW_GAME_TEXT := "最初からやり直す"
const NEW_GAME_CONFIRM_TEXT := "本当にやり直す（もう一度押す）"

# やり直しは取り消せないので、1回目の押下では確認だけを行う
var _confirming_new_game := false

@onready var resume_button: Button = %ResumeButton
@onready var save_button: Button = %SaveButton
@onready var new_game_button: Button = %NewGameButton
@onready var quit_button: Button = %QuitButton
@onready var status_label: Label = %StatusLabel


func _ready() -> void:
	visible = false
	resume_button.pressed.connect(close)
	save_button.pressed.connect(func(): save_requested.emit())
	new_game_button.pressed.connect(_on_new_game_pressed)
	quit_button.pressed.connect(func(): quit_requested.emit())
	_reset_transient_state()


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
	_reset_transient_state()
	visible = true
	get_tree().paused = true
	resume_button.grab_focus()


func close() -> void:
	visible = false
	get_tree().paused = false


func show_status(text: String) -> void:
	status_label.text = text


func _on_new_game_pressed() -> void:
	if not _confirming_new_game:
		_confirming_new_game = true
		new_game_button.text = NEW_GAME_CONFIRM_TEXT
		return
	new_game_requested.emit()


func _reset_transient_state() -> void:
	_confirming_new_game = false
	new_game_button.text = NEW_GAME_TEXT
	status_label.text = ""
