class_name Player
extends CharacterBody2D

# Player - プレイヤーキャラクター
# hex座標系での移動とゲーム操作を管理する

var current_hex_position: Hex
var target_hex_position: Hex

func _init():
	# 初期位置は中央hex座標(0,0)
	current_hex_position = Hex.new(0, 0)

func move_to_hex(hex_coord: Hex):
	# 移動目標を設定
	target_hex_position = hex_coord