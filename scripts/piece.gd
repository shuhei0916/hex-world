class_name Piece
extends Node2D

# Piece - ピースオブジェクト
# Unity版のPiece.csをGodotに移植

var shape: Array = []
var color: Color = Color.WHITE
var layout: Layout

func _init():
	# レイアウト設定（Unity版と同じ設定）
	layout = Layout.new(
		Layout.layout_pointy,
		Vector2(0.6, 0.6),
		Vector2(0.0, 0.0)
	)

# ピースを初期化
func initialize(piece_shape: Array, piece_color: Color):
	shape = piece_shape
	color = piece_color

# ワールド座標をHex座標に変換
func world_position_to_hex(world_pos: Vector2) -> Hex:
	return Layout.pixel_to_hex_rounded(layout, world_pos)

# 指定のHex位置に配置可能かチェック
func can_place_at_hex(base_hex: Hex) -> bool:
	return GridManager.can_place(shape, base_hex)

# ピースを指定のHex位置に配置
func place_at_hex(base_hex: Hex):
	GridManager.place_piece(shape, base_hex)

# ピースを指定のHex位置から解除
func unplace_from_hex(base_hex: Hex):
	GridManager.unplace_piece(shape, base_hex)