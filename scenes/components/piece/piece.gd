class_name Piece
extends Node2D

# ピースの種類ID (TetrahexShapes.TetrahexType)
var piece_type: int = 0

# このピースが占有しているHex座標のリスト
var hex_coordinates: Array[Hex] = []

func setup(data: Dictionary):
	if data.has("type"):
		piece_type = data["type"]
	
	if data.has("hex_coordinates"):
		# 参照渡しではなくコピーを作成して保持する
		hex_coordinates.clear()
		var coords = data["hex_coordinates"]
		if coords is Array:
			for hex in coords:
				if hex is Hex:
					hex_coordinates.append(hex)