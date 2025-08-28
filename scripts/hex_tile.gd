class_name HexTile
extends Node2D

# HexTile - 個別の六角形タイル表示
# Unity版のhexPrefab相当

var hex_coordinate: Hex

func setup_hex(hex: Hex):
	hex_coordinate = hex
	# 将来的にテクスチャ設定やビジュアル調整