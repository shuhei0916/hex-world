class_name HexGrid
extends RefCounted

# HexGrid - chunk にどのマスがあるか（盤面の形）だけを持つ。
# マスが埋まっているかは PieceRegistry が持つ。

var _hexes: Dictionary[Vector2i, bool] = {}


# 盤面のマスを hexes にそっくり入れ替える（前の形のマスは残さない）
func set_hexes(hexes: Array[Vector2i]) -> void:
	_hexes.clear()
	for hex in hexes:
		_hexes[hex] = true


func is_inside_grid(hex: Vector2i) -> bool:
	return _hexes.has(hex)
