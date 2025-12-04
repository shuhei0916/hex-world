@tool
class_name HexTile
extends Node2D

# HexTile - 個別の六角形タイル表示
# Unity版のhexPrefab相当

var hex_coordinate: Hex
var is_highlighted: bool = false
var normal_color: Color = Color("#3D3D3D")
var highlight_color: Color = Color("#7c7c7c")
var _current_color: Color # 追加: 現在のHexの色 (ピースの色が優先される)

func setup_hex(hex: Hex):
	hex_coordinate = hex
	_current_color = normal_color # 初期色を設定
	_update_sprite_color() # スプライトの色を更新
	set_highlight(false)

# ハイライト状態を設定
func set_highlight(highlighted: bool):
	is_highlighted = highlighted
	_update_sprite_color()

# ピースの色を設定
func set_color(color: Color):
	_current_color = color
	_update_sprite_color()

# 現在のピースの色を取得
func get_color() -> Color:
	return _current_color

# 透明度を設定
func set_transparency(alpha: float):
	_current_color.a = clampf(alpha, 0.0, 1.0) # アルファ値を0.0から1.0の範囲に制限
	_update_sprite_color()

# スプライトの色を更新するヘルパー
func _update_sprite_color():
	var sprite = get_node_or_null("Sprite2D")
	if sprite:
		if is_highlighted:
			sprite.modulate = highlight_color
		else:
			sprite.modulate = _current_color
