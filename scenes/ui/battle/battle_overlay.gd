class_name BattleOverlay
extends CanvasLayer
## 戦闘画面をほかの画面の上に重ねて出す。決着したら結果を見せ、閉じるときに勝敗を知らせる。

## 戦闘を終えて閉じた。撤退したときは負けた扱い。
signal closed(won: bool)

const BattleSceneScene := preload("res://scenes/ui/battle/battle_scene.tscn")
const VICTORY_TEXT := "勝利！ この chunk を解放した"
const DEFEAT_TEXT := "敗北… 何度でも挑める"
## 戦闘画面のスキルなどの表示（BattleScene の Hud）より手前に出す
const UI_LAYER_OFFSET := 2
## 画面の下に並ぶスキルの高さ。盤面はこの上の領域の中央に置く
const SKILL_BAR_HEIGHT := 96.0
const RESULT_PANEL_COLOR := Color("#1e222c")

## いま表示している戦闘の画面。閉じているあいだは null。
var battle_scene: BattleScene
## false にすると戦闘の行動をアニメーションなしですぐ表示する。
var animations_enabled := true

var _won := false
var _ui := CanvasLayer.new()
var _holder := Node2D.new()
var _retreat_button := Button.new()
var _result_panel := PanelContainer.new()
var _result_label := Label.new()


func _init() -> void:
	layer = 10
	visible = false
	var background := ColorRect.new()
	background.name = "Background"
	background.color = HexStyle.BACKGROUND_COLOR
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	# 盤面のクリックは BattleScene が受け取るので、背景では止めない
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)
	_holder.name = "Holder"
	add_child(_holder)
	_build_ui()


func _ready() -> void:
	get_viewport().size_changed.connect(_center_battle_scene)


func is_open() -> bool:
	return battle_scene != null


## skill_turn の戦闘を表示する。
func open(skill_turn: SkillTurn) -> void:
	_remove_battle_scene()
	_won = false
	battle_scene = BattleSceneScene.instantiate()
	battle_scene.skill_turn = skill_turn
	battle_scene.animations_enabled = animations_enabled
	battle_scene.battle_finished.connect(_on_battle_finished)
	_holder.add_child(battle_scene)
	_center_battle_scene()
	_result_panel.visible = false
	_retreat_button.visible = true
	_set_shown(true)


## 決着の前に戦闘をやめて閉じる。負けた扱いになる。
func retreat() -> void:
	if is_open() and not is_result_shown():
		_close()


## 決着の結果を見終えて閉じる。
func confirm_result() -> void:
	if is_result_shown():
		_close()


func is_result_shown() -> bool:
	return _result_panel.visible


func get_result_text() -> String:
	return _result_label.text


func _on_battle_finished(outcome: Battle.Outcome) -> void:
	_won = outcome == Battle.Outcome.VICTORY
	_result_label.text = VICTORY_TEXT if _won else DEFEAT_TEXT
	_result_panel.visible = true
	_retreat_button.visible = false


func _close() -> void:
	_remove_battle_scene()
	_result_panel.visible = false
	_set_shown(false)
	closed.emit(_won)


func _remove_battle_scene() -> void:
	if battle_scene == null:
		return
	_holder.remove_child(battle_scene)
	battle_scene.queue_free()
	battle_scene = null


func _center_battle_scene() -> void:
	if battle_scene == null:
		return
	var size := get_viewport().get_visible_rect().size
	battle_scene.position = Vector2(size.x / 2.0, (size.y - SKILL_BAR_HEIGHT) / 2.0)


## CanvasLayer を隠しても子の CanvasLayer は隠れないので、合わせて切り替える。
func _set_shown(shown: bool) -> void:
	visible = shown
	_ui.visible = shown


func _build_ui() -> void:
	_ui.name = "Ui"
	_ui.layer = layer + UI_LAYER_OFFSET
	_ui.visible = false
	add_child(_ui)
	_retreat_button.name = "RetreatButton"
	_retreat_button.text = "撤退する"
	_retreat_button.focus_mode = Control.FOCUS_NONE
	_retreat_button.anchor_left = 1.0
	_retreat_button.anchor_right = 1.0
	_retreat_button.offset_left = -136.0
	_retreat_button.offset_right = -16.0
	_retreat_button.offset_top = 12.0
	_retreat_button.offset_bottom = 52.0
	_retreat_button.pressed.connect(retreat)
	_ui.add_child(_retreat_button)
	_result_panel.name = "ResultPanel"
	_result_panel.visible = false
	_result_panel.anchor_left = 0.5
	_result_panel.anchor_right = 0.5
	_result_panel.anchor_top = 0.5
	_result_panel.anchor_bottom = 0.5
	_result_panel.offset_left = -220.0
	_result_panel.offset_right = 220.0
	_result_panel.offset_top = -90.0
	_result_panel.offset_bottom = 90.0
	var style := StyleBoxFlat.new()
	style.bg_color = RESULT_PANEL_COLOR
	style.set_corner_radius_all(8)
	_result_panel.add_theme_stylebox_override("panel", style)
	_ui.add_child(_result_panel)
	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 20)
	_result_panel.add_child(box)
	_result_label.name = "ResultLabel"
	_result_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_result_label.add_theme_font_size_override("font_size", 28)
	box.add_child(_result_label)
	var confirm_button := Button.new()
	confirm_button.name = "ConfirmButton"
	confirm_button.text = "地図に戻る"
	confirm_button.focus_mode = Control.FOCUS_NONE
	confirm_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	confirm_button.pressed.connect(confirm_result)
	box.add_child(confirm_button)
