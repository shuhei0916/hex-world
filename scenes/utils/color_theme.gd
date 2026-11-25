class_name ColorTheme
extends RefCounted

## 見た目の配色。いまの暗い見た目（ダーク）と、紙のボードゲームのような明るい見た目（ライト。
## 参考: docs/board_game_image01〜04 の、紙のヘックスマップにインクの線）を切り替える。
## 色は名前で引く（ColorTheme.color(&"floor")）。描くたびに引けば、切り替えたときに
## 描き直すだけで新しい配色になる。切り替えは notifier の changed で知らせる。
## 選んだ配色はゲームの進行とは別の設定ファイルに残す。

enum Mode { DARK, LIGHT }


# 切り替えを知らせる相手。static な signal は持てないので、オブジェクトに持たせる
class Notifier:
	extends RefCounted
	signal changed


const DEFAULT_SETTINGS_PATH := "user://settings.cfg"
const _SECTION := "display"
const _KEY := "color_theme"
# ライトでのバイオームの色を、紙の色にどれだけ寄せるか
const _MAP_PAPER_MIX := 0.45
# ライトのインク（文字・線画の色）と紙の色
const _INK := Color("#3b2f2a")
const _PAPER := Color("#f3eee2")

const DARK := {
	# ---- 盤面 ----
	&"background": Color("#14161b"),  # マスの無いところの地
	&"floor": Color(0.24, 0.27, 0.32),  # 何も無い床のマス
	&"wall": Color(0.09, 0.1, 0.12),  # 通れないマス（戦闘の壁）
	&"border": Color(0.05, 0.06, 0.08),  # マスとマスを区切る線
	&"landing_hint": Color(0.55, 0.35, 0.25),  # 橋の着地点のヒント
	&"neighbor_modulate": Color(0.78, 0.78, 0.8),  # 所有している隣の chunk
	&"unowned_modulate": Color(0.42, 0.42, 0.46),  # 所有していない隣の chunk
	&"reach_fill": Color(1.0, 1.0, 1.0, 0.08),  # キャラクターから届く範囲
	&"player_outline": Color(0.1, 0.12, 0.16),
	# ---- 設置物 ----
	&"piece_outline": Color("#3c4652"),
	&"port_marker": Color(0.12, 0.12, 0.14, 0.85),
	&"belt_fill": Color(0.77, 0.77, 0.77),
	&"belt_edge": Color(0.54, 0.54, 0.57),
	&"belt_arrow": Color(0.62, 0.62, 0.62),
	&"bridge_unconnected": Color(0.77, 0.77, 0.77, 0.3),
	# ---- ワールドマップ ----
	&"fog": Color("#1d2026"),
	&"frontier_veil": Color.BLACK,  # 挑戦できる chunk のバイオーム色を沈める先
	&"map_marker": Color("#f4f1ea"),  # 今いる chunk の印
	&"map_hover": Color(1.0, 1.0, 1.0, 0.12),  # ホバー中の chunk に重ねる色
	&"card_background": Color("#323848", 0.95),
	&"card_text": Color("#e8eaf0"),
	&"card_arrow": Color("#7ee8a0"),
	# ---- 画面の部品 ----
	&"text": Color(0.875, 0.875, 0.875),
	&"text_dim": Color(0.72, 0.75, 0.8),
	&"text_title": Color(0.55, 0.6, 0.68),
	&"text_strong": Color(1, 1, 1),
	&"text_good": Color(0.55, 0.9, 0.55),
	&"text_bad": Color(1.0, 0.55, 0.5),
	&"text_notice": Color(1.0, 0.82, 0.45),
	&"text_intent": Color(1, 0.7, 0.2),  # 戦闘の敵の予定
	&"panel": Color(0.09, 0.1, 0.13),
	&"panel_border": Color(0.45, 0.5, 0.6),
	&"panel_inner": Color(0.13, 0.15, 0.19),
	&"panel_band": Color(1, 1, 1, 0.03),
	&"button_fill": Color(0.13, 0.16, 0.22),
	&"button_hover": Color(0.19, 0.23, 0.31),
	&"button_pressed": Color(0.18, 0.55, 0.72),
	&"button_disabled": Color(0.10, 0.12, 0.16),
	&"button_outline": Color(0.32, 0.38, 0.48),
	&"button_outline_pressed": Color(0.62, 0.90, 1.0),
	&"button_hint": Color(1, 1, 1, 0.55),
	&"button_icon": Color.WHITE,  # アイコン（白い線画）に掛ける色
	&"disabled_modulate": Color(0.4, 0.4, 0.4),  # 解放していないボタン
	&"dimmer": Color(0, 0, 0, 0.55),  # メニューの後ろを覆う幕
	&"link": Color("#3c4452"),
	&"link_done": Color("#4fa3d9"),
	&"research_done": Color("#4fa3d9"),
	&"research_available": Color("#e0b44a"),
	&"research_unaffordable": Color("#5a6478"),
	&"research_locked": Color("#2c323d"),
	&"research_name": Color(0.9, 0.92, 0.96),
	&"research_name_locked": Color(0.55, 0.58, 0.64),
	&"selected_outline": Color(1, 1, 1),
}

const LIGHT := {
	# ---- 盤面 ----
	&"background": Color("#d9ccb2"),
	&"floor": _PAPER,
	&"wall": Color("#c2ad8a"),
	&"border": Color("#b0604a"),
	&"landing_hint": Color("#e9b99a"),
	&"neighbor_modulate": Color(0.96, 0.94, 0.9),
	&"unowned_modulate": Color(0.86, 0.79, 0.69),
	&"reach_fill": Color(_INK, 0.07),
	&"player_outline": _INK,
	# ---- 設置物 ----
	&"piece_outline": _INK,
	&"port_marker": Color(_INK, 0.85),
	&"belt_fill": Color("#e2d7c1"),
	&"belt_edge": Color("#7d6a58"),
	&"belt_arrow": Color("#a08c76"),
	&"bridge_unconnected": Color("#7d6a58", 0.3),
	# ---- ワールドマップ ----
	&"fog": Color("#cdbd9f"),
	&"frontier_veil": Color("#cdbd9f"),  # 霧と同じ色に寄せる
	&"map_marker": Color("#b0402c"),
	&"map_hover": Color(_INK, 0.1),
	&"card_background": Color("#fbf8f1", 0.95),
	&"card_text": _INK,
	&"card_arrow": Color("#2f8a52"),
	# ---- 画面の部品 ----
	&"text": _INK,
	&"text_dim": Color("#6b5c50"),
	&"text_title": Color("#8a7766"),
	&"text_strong": Color("#2a201c"),
	&"text_good": Color("#2f8a3e"),
	&"text_bad": Color("#c0432f"),
	&"text_notice": Color("#a8660f"),
	&"text_intent": Color("#b85a12"),
	&"panel": Color("#f7f2e7"),
	&"panel_border": Color("#8a7766"),
	&"panel_inner": Color("#ebe3d2"),
	&"panel_band": Color(_INK, 0.04),
	&"button_fill": Color("#f3ecdc"),
	&"button_hover": Color("#e6dcc6"),
	&"button_pressed": Color("#e8b85a"),
	&"button_disabled": Color("#ddd3bf"),
	&"button_outline": Color("#8a7766"),
	&"button_outline_pressed": _INK,
	&"button_hint": Color(_INK, 0.6),
	&"button_icon": _INK,
	&"disabled_modulate": Color(1, 1, 1, 0.4),
	&"dimmer": Color(_INK, 0.3),
	&"link": Color("#c4b59c"),
	&"link_done": Color("#3f8fc4"),
	&"research_done": Color("#5aa6d8"),
	&"research_available": Color("#e6b54a"),
	&"research_unaffordable": Color("#c9bba3"),
	&"research_locked": Color("#e4dac7"),
	&"research_name": _INK,
	&"research_name_locked": Color("#9a8a7a"),
	&"selected_outline": _INK,
}

## 設定ファイルの場所（テストやツールは本物の設定を触らないよう差し替える）
static var settings_path := DEFAULT_SETTINGS_PATH
static var mode: Mode = Mode.DARK
static var notifier := Notifier.new()
static var _ui_theme: Theme = null


static func is_light() -> bool:
	return mode == Mode.LIGHT


static func set_mode(new_mode: Mode) -> void:
	if new_mode == mode:
		return
	mode = new_mode
	notifier.changed.emit()


static func toggle() -> void:
	set_mode(Mode.DARK if is_light() else Mode.LIGHT)


## いまの配色での、名前 key の色
static func color(key: StringName) -> Color:
	var table: Dictionary = LIGHT if is_light() else DARK
	if not table.has(key):
		push_error("ColorTheme: 色の名前がありません: %s" % key)
		return Color.MAGENTA
	return table[key]


## ワールドマップのバイオームの色。ライトでは紙の色に寄せて、水彩で塗ったように淡くする
static func map_color(base: Color) -> Color:
	return base.lerp(_PAPER, _MAP_PAPER_MIX) if is_light() else base


## 画面の部品（ラベル・ボタン・パネル）の見た目。ダークは Godot の標準のまま（null）
static func ui_theme() -> Theme:
	if not is_light():
		return null
	if _ui_theme == null:
		_ui_theme = _build_light_ui_theme()
	return _ui_theme


static func save_settings(path: String = "") -> void:
	path = path if path != "" else settings_path
	var config := ConfigFile.new()
	config.load(path)  # 他の設定があれば残す
	config.set_value(_SECTION, _KEY, "light" if is_light() else "dark")
	config.save(path)


static func load_settings(path: String = "") -> void:
	path = path if path != "" else settings_path
	var config := ConfigFile.new()
	if config.load(path) != OK:
		return
	set_mode(Mode.LIGHT if config.get_value(_SECTION, _KEY, "dark") == "light" else Mode.DARK)


static func _build_light_ui_theme() -> Theme:
	var theme := Theme.new()
	var table: Dictionary = LIGHT
	for type in ["Label", "Button", "CheckBox", "LinkButton"]:
		theme.set_color("font_color", type, table[&"text"])
	theme.set_color("font_hover_color", "Button", table[&"text_strong"])
	theme.set_color("font_pressed_color", "Button", table[&"text_strong"])
	theme.set_color("font_focus_color", "Button", table[&"text_strong"])
	theme.set_color("font_hover_pressed_color", "Button", table[&"text_strong"])
	theme.set_color("font_disabled_color", "Button", table[&"research_name_locked"])
	theme.set_color("font_color", "TooltipLabel", table[&"text"])
	var border: Color = table[&"button_outline"]
	theme.set_stylebox("normal", "Button", _box(table[&"button_fill"], border))
	theme.set_stylebox("hover", "Button", _box(table[&"button_hover"], border))
	theme.set_stylebox("pressed", "Button", _box(table[&"button_pressed"], border))
	theme.set_stylebox("hover_pressed", "Button", _box(table[&"button_pressed"], border))
	theme.set_stylebox("disabled", "Button", _box(table[&"button_disabled"], border))
	theme.set_stylebox("focus", "Button", StyleBoxEmpty.new())
	theme.set_stylebox("panel", "PanelContainer", _box(table[&"panel"], table[&"panel_border"]))
	theme.set_stylebox("panel", "Panel", _box(table[&"panel"], table[&"panel_border"]))
	theme.set_stylebox("panel", "TooltipPanel", _box(table[&"panel"], table[&"panel_border"]))
	return theme


static func _box(fill: Color, border: Color) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = fill
	box.border_color = border
	box.set_border_width_all(1)
	box.set_corner_radius_all(4)
	box.content_margin_left = 8
	box.content_margin_right = 8
	box.content_margin_top = 4
	box.content_margin_bottom = 4
	return box
