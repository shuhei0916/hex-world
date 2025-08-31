class_name Player
extends CharacterBody2D

# Player - プレイヤーキャラクター
# hex座標系での移動とゲーム操作を管理する

var current_hex_position: Hex
var target_hex_position: Hex
var movement_path: Array[Hex] = []
var is_moving: bool = false

func _init():
	# 初期位置は中央hex座標(0,0)
	current_hex_position = Hex.new(0, 0)

func move_to_hex(hex_coord: Hex):
	# 移動目標を設定
	target_hex_position = hex_coord
	# hex経路を計算
	calculate_movement_path()

# hexグリッド経路を計算（直線経路）
func calculate_movement_path():
	if not target_hex_position:
		return
	
	movement_path.clear()
	
	# 現在位置から目標位置への直線経路を生成
	var start = current_hex_position
	var end = target_hex_position
	
	# linedraw関数を使用して経路を計算
	movement_path = Hex.linedraw(start, end)
	
	# 現在位置は除外（既にいるため）
	if movement_path.size() > 0 and Hex.equals(movement_path[0], start):
		movement_path.remove_at(0)