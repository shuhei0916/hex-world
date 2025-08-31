class_name Player
extends Node2D

# Player - プレイヤーキャラクター
# hex座標系での移動とゲーム操作を管理する

var current_hex_position: Hex

func _init():
	# 初期位置は中央hex座標(0,0)
	current_hex_position = Hex.new(0, 0)
	
	# Sprite2Dを作成してicon.svgを設定
	var sprite = Sprite2D.new()
	sprite.name = "Sprite2D"
	sprite.texture = load("res://assets/icon.svg")
	add_child(sprite)