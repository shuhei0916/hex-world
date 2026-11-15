class_name BattleScene
extends Node2D
## 1戦を表示し、手札のカードとクリックを主人公の行動に変える。

## 行動のアニメーションをすべて再生し終えた。
signal animations_finished
## 戦闘が決着し、その結果を画面に出し終えた。1戦につき一度だけ知らせる。
signal battle_finished(outcome: Battle.Outcome)

const HEX_SIZE := 40.0
## 1マス歩くのにかける秒数。
const STEP_TIME := 0.12

## 表示する戦闘の、主人公の手番。シーンツリーに入れる前に必ず入れておく。
var card_turn: CardTurn
var battle: Battle
var selected_card: Card
## false にすると行動の結果をアニメーションなしですぐ表示する。
var animations_enabled := true
## アニメーションの再生中。このあいだは操作を受け付けない。
var is_animating := false

var _animations: Array[Callable] = []
var _views: Dictionary[Unit, UnitView] = {}
var _hovered := Vector2i.ZERO
var _finish_notified := false

@onready var _board: BoardView = $Board
@onready var _units: Node2D = $Units
@onready var _effects: Node2D = $Effects
@onready var _energy_label: Label = $Hud/EnergyLabel
@onready var _turn_label: Label = $Hud/TurnLabel
@onready var _intent_label: Label = $Hud/IntentLabel
@onready var _end_turn_button: Button = $Hud/EndTurnButton
@onready var _hand: HBoxContainer = $Hud/Hand


func _ready() -> void:
	battle = card_turn.battle
	_board.hex_size = HEX_SIZE
	_end_turn_button.pressed.connect(end_turn)
	battle.unit_moved.connect(_on_unit_moved)
	battle.unit_attacked.connect(_on_unit_attacked)
	battle.unit_died.connect(_on_unit_died)
	refresh()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		hover_hex(BattleHex.from_pixel(get_local_mouse_position(), HEX_SIZE))
	elif (
		event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT
	):
		click_hex(BattleHex.from_pixel(get_local_mouse_position(), HEX_SIZE))
	elif event.is_action_pressed("ui_accept"):
		end_turn()


## マスを選んだときの操作。選んでいるカードをそのマスに使う。
func click_hex(hex: Vector2i) -> void:
	if is_animating:
		return
	if selected_card != null and card_turn.play(selected_card, hex):
		selected_card = null
	_show_result()


## マウスがマスに乗ったときの操作。敵のいるマスなら、その敵の予定を示す。
func hover_hex(hex: Vector2i) -> void:
	_hovered = hex
	_board.hovered = hex
	_refresh_intent()
	_board.queue_redraw()


## 手札のカードを選ぶ。選んでいるカードをもう一度選ぶと選択を外す。
## マスを選ぶ必要のないカードは、選んだ時点で使う。
func select_card(card: Card) -> void:
	if is_animating:
		return
	if not card.needs_target():
		selected_card = null
		card_turn.play(card, battle.player.position)
		_show_result()
		return
	var selectable := card.cost <= card_turn.energy
	selected_card = card if selectable and selected_card != card else null
	refresh()


func end_turn() -> void:
	if is_animating:
		return
	if battle.outcome() == Battle.Outcome.ONGOING:
		selected_card = null
		card_turn.end_turn()
	_show_result()


## ユニットの表示を返す。戦場にいなければ null。
func view_of(unit: Unit) -> UnitView:
	return _views.get(unit)


func _on_unit_moved(unit: Unit, path: Array[Vector2i]) -> void:
	_animations.append(_animate_move.bind(_views[unit], path))


func _on_unit_attacked(
	attacker: Unit, target: Unit, damage: int, hp_after: int, block_after: int
) -> void:
	_animations.append(
		_animate_attack.bind(_views[attacker], _views[target], damage, hp_after, block_after)
	)


func _on_unit_died(unit: Unit) -> void:
	_animations.append(_animate_death.bind(_views[unit]))


## 行動の結果を画面に出す。起きた出来事があれば順にアニメーションしてから反映する。
func _show_result() -> void:
	if not animations_enabled or _animations.is_empty():
		_animations.clear()
		refresh()
		return
	is_animating = true
	_board.reachable.clear()
	_refresh_intent()
	_board.queue_redraw()
	_refresh_hand(false)
	_end_turn_button.disabled = true
	while not _animations.is_empty():
		await _animations.pop_front().call()
	is_animating = false
	refresh()
	animations_finished.emit()


func _animate_move(view: UnitView, path: Array[Vector2i]) -> void:
	var tween := create_tween()
	for hex in path.slice(1):
		tween.tween_property(view, "position", BattleHex.to_pixel(hex, HEX_SIZE), STEP_TIME)
	await tween.finished


## 相手に向かって踏み込み、当たった瞬間にHPの表示を減らして元の位置に戻る。
func _animate_attack(
	attacker: UnitView, target: UnitView, damage: int, hp_after: int, block_after: int
) -> void:
	var origin := attacker.position
	var lunge := create_tween()
	lunge.tween_property(attacker, "position", origin.lerp(target.position, 0.4), 0.08)
	await lunge.finished
	target.show_hp(hp_after)
	target.show_block(block_after)
	_spawn_damage_number(target.position, damage)
	target.modulate = Color(2.5, 2.5, 2.5)
	var recover := create_tween().set_parallel()
	recover.tween_property(attacker, "position", origin, 0.14)
	recover.tween_property(target, "modulate", Color.WHITE, 0.25)
	await recover.finished


func _animate_death(view: UnitView) -> void:
	var tween := create_tween()
	tween.tween_property(view, "modulate:a", 0.0, 0.25)
	await tween.finished


## ダメージの数字を出す。浮かび上がりながら消える。ブロックで防ぎきったら「防御」と出す。
func _spawn_damage_number(at: Vector2, damage: int) -> void:
	var label := Label.new()
	label.text = "-%d" % damage if damage > 0 else "防御"
	label.position = at + Vector2(-12.0, -52.0)
	label.add_theme_font_size_override("font_size", 24)
	label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
	_effects.add_child(label)
	var tween := label.create_tween().set_parallel()
	tween.tween_property(label, "position:y", label.position.y - 28.0, 0.6)
	tween.tween_property(label, "modulate:a", 0.0, 0.6)
	tween.chain().tween_callback(label.queue_free)


## 戦闘のいまの状態を画面に反映する。
func refresh() -> void:
	_sync_unit_views()
	var ongoing := battle.outcome() == Battle.Outcome.ONGOING
	_board.field = battle.field
	_board.reachable.clear()
	if ongoing:
		_board.reachable = battle.field.reachable(battle.player.position, _move_range())
	_refresh_intent()
	_board.queue_redraw()
	_refresh_hand(ongoing)
	_energy_label.text = (
		"マナ: %d / %d (山札 %d / 捨て札 %d)"
		% [
			card_turn.energy,
			CardTurn.ENERGY_PER_TURN,
			card_turn.deck.draw_pile.size(),
			card_turn.deck.discard_pile.size(),
		]
	)
	_turn_label.text = "ターン %d" % battle.turn
	_end_turn_button.disabled = not ongoing
	if not ongoing and not _finish_notified:
		_finish_notified = true
		battle_finished.emit(battle.outcome())


## マウスを乗せている敵の、攻撃されうるマスと次の手番の予定を盤面と文に出す。
func _refresh_intent() -> void:
	_board.threatened.clear()
	_board.plan_path.clear()
	_board.plan_attacks = false
	_intent_label.text = ""
	if is_animating or battle.outcome() != Battle.Outcome.ONGOING:
		return
	var enemy := battle.field.unit_at(_hovered)
	if enemy == null or enemy.team != Unit.Team.ENEMY:
		return
	var plan := battle.plan_of(enemy)
	_board.threatened = battle.threatened_hexes_by(enemy)
	_board.plan_path = plan.path
	_board.plan_attacks = plan.attacks
	_board.plan_target = battle.player.position
	_intent_label.text = "敵の予定: " + _describe(plan, enemy)


func _describe(plan: EnemyPlan, enemy: Unit) -> String:
	var steps := plan.path.size() - 1
	var attack := "攻撃（%dダメージ）" % enemy.attack_power
	if steps > 0 and plan.attacks:
		return "%dマス移動して%s" % [steps, attack]
	if steps > 0:
		return "%dマス移動" % steps
	return attack if plan.attacks else "動かない"


## いま主人公が歩ける歩数。選んでいる移動カードの歩数になる。
func _move_range() -> int:
	if selected_card != null and selected_card.kind == Card.Kind.MOVE:
		return selected_card.value
	return 0


func _refresh_hand(ongoing: bool) -> void:
	for button in _hand.get_children():
		_hand.remove_child(button)
		button.queue_free()
	for card in card_turn.deck.hand:
		var button := Button.new()
		button.text = "%s (%d)\n%s" % [card.title, card.cost, card.description()]
		button.custom_minimum_size = Vector2(110.0, 72.0)
		button.focus_mode = Control.FOCUS_NONE
		button.toggle_mode = true
		button.button_pressed = card == selected_card
		button.disabled = not ongoing or card.cost > card_turn.energy
		button.pressed.connect(select_card.bind(card))
		_hand.add_child(button)


func _sync_unit_views() -> void:
	var alive := battle.field.units()
	for unit in _views.keys():
		if not alive.has(unit):
			_views[unit].free()
			_views.erase(unit)
	for unit in alive:
		if not _views.has(unit):
			var view := UnitView.new()
			view.unit = unit
			_units.add_child(view)
			_views[unit] = view
		_views[unit].refresh(HEX_SIZE)
