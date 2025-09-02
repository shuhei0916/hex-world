class_name HexTile
extends Node2D

# HexTile - 個別の六角形タイル表示
# Unity版のhexPrefab相当

var hex_coordinate: Hex
var is_highlighted: bool = false
var normal_color: Color = Color("#3D3D3D")
var highlight_color: Color = Color("#7c7c7c")

func setup_hex(hex: Hex):
	hex_coordinate = hex
	# デフォルト色を設定
	set_highlight(false)

# ハイライト状態を設定
func set_highlight(highlighted: bool):
	is_highlighted = highlighted
	var sprite = get_node_or_null("Sprite2D")
	if sprite:
		if highlighted:
			sprite.modulate = highlight_color
		else:
			sprite.modulate = normal_color