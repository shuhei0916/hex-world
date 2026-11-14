@tool
class_name HexTile
extends Node2D

# HexTile - 個別の六角形タイル表示
# Unity版のhexPrefab相当

# マスの画像（pointy-top）。ワールドマップの chunk のタイルは同じ形・陰影の flat-top 版で描く
const TEXTURE = preload("res://assets/HexagonRounded.png")
const FLAT_TEXTURE = preload("res://assets/HexagonRoundedFlat.png")
# 画像の中の六角形の形（tools/generate_rounded_hex.gd がこの値で画像を作る）。
# 丸める前の頂点までの距離と、角の丸みの半径（どちらも画像のピクセル単位）
const TEXTURE_CIRCUMRADIUS := 128.0
const TEXTURE_CORNER_RADIUS := 26.0

var hex_coordinate: Hex
var is_highlighted: bool = false
var normal_color: Color = Color("#3D3D3D")
# 橋の着地点（受け取りを置く場所）のヒント用の色
var highlight_color: Color = Color(0.55, 0.35, 0.25)
var _current_color: Color  # 追加: 現在のHexの色 (ピースの色が優先される)

@onready var _sprite: Sprite2D = $Sprite2D


func setup_hex(hex: Hex):
	hex_coordinate = hex
	_current_color = normal_color  # 初期色を設定
	_update_sprite_color()  # スプライトの色を更新
	set_highlight(false)


# ハイライト状態を設定
func set_highlight(highlighted: bool):
	is_highlighted = highlighted
	_update_sprite_color()


# ピースの色を設定
func set_color(color: Color):
	_current_color = color
	_update_sprite_color()


# 色をリセット
func reset_color():
	_current_color = normal_color
	_update_sprite_color()


# 現在のピースの色を取得
func get_color() -> Color:
	return _current_color


# 透明度を設定
func set_transparency(alpha: float):
	_current_color.a = clampf(alpha, 0.0, 1.0)  # アルファ値を0.0から1.0の範囲に制限
	_update_sprite_color()


# スプライトの色を更新するヘルパー
func _update_sprite_color():
	if not _sprite:
		return
	if is_highlighted:
		_sprite.modulate = highlight_color
	else:
		_sprite.modulate = _current_color
