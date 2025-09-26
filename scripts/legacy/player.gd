class_name Player
extends CharacterBody2D

# Player - プレイヤーキャラクター
# hex座標系での移動とゲーム操作を管理する

# 移動経路ハイライト用シグナル
signal path_highlight_requested(path: Array[Hex])
signal path_highlight_cleared()

const HexGraph = preload("res://scripts/hex_graph.gd")
const AStarPathfinder = preload("res://scripts/a_star_pathfinder.gd")

var current_hex_position: Hex
var target_hex_position: Hex
var movement_path: Array[Hex] = []
var is_moving: bool = false
var grid_layout: Layout
var move_speed: float = 200.0  # ピクセル/秒
var current_target_pixel: Vector2
var next_hex_index: int = 0

# A*パスファインディング用
var hex_graph: HexGraph
var pathfinder: AStarPathfinder

func _init():
	# 初期位置は中央hex座標(0,0)
	current_hex_position = Hex.new(0, 0)
	
	# A*パスファインディングコンポーネントを初期化
	hex_graph = HexGraph.new()
	pathfinder = AStarPathfinder.new()
	
	# グリッドの境界を設定（現在は半径4のグリッドを使用）
	hex_graph.set_bounds(4)

# グリッドレイアウトを設定し、プレイヤーを正しい位置に配置
func setup_grid_layout(layout: Layout):
	grid_layout = layout
	# 現在のhex座標に基づいてピクセル位置を設定
	update_position_to_hex_center()

# グリッド境界を設定（GridDisplayから呼び出される）
func set_grid_bounds(radius: int):
	if hex_graph:
		hex_graph.set_bounds(radius)

# プレイヤーを現在のhex座標の中央に正確に配置
func update_position_to_hex_center():
	if grid_layout and current_hex_position:
		var center_position = hex_to_pixel_position(current_hex_position)
		global_position = center_position
		print("プレイヤーを hex(", current_hex_position.q, ",", current_hex_position.r, ") の中央 ", center_position, " に配置")

func move_to_hex(hex_coord: Hex):
	# 移動目標を設定
	target_hex_position = hex_coord
	# hex経路を計算
	calculate_movement_path()
	# 移動開始
	start_movement()

# プレビュー用の経路計算（実際の移動は行わない）
func preview_path_to_hex(hex_coord: Hex) -> Array[Hex]:
	if not hex_coord:
		return []
	
	# 現在位置から指定位置への経路をA*で計算
	var preview_path = pathfinder.find_path(hex_graph, current_hex_position, hex_coord)
	
	# パスが見つからなかった場合は直線経路にフォールバック
	if preview_path.is_empty():
		preview_path = Hex.linedraw(current_hex_position, hex_coord)
	
	# 現在位置は除外（既にいるため）
	if preview_path.size() > 0 and Hex.equals(preview_path[0], current_hex_position):
		preview_path.remove_at(0)
	
	return preview_path

# 移動を開始
func start_movement():
	if movement_path.size() > 0:
		is_moving = true
		next_hex_index = 0
		set_next_target_pixel()
		# 移動開始時はプレビューハイライトをクリア（実際の移動が開始されるため）
		path_highlight_cleared.emit()

# hexグリッド経路を計算（A*パスファインディング）
func calculate_movement_path():
	if not target_hex_position:
		return
	
	movement_path.clear()
	
	# 現在位置から目標位置への最適経路をA*で計算
	var start = current_hex_position
	var end = target_hex_position
	
	# A*アルゴリズムを使用して経路を計算
	movement_path = pathfinder.find_path(hex_graph, start, end)
	
	# パスが見つからなかった場合は直線経路にフォールバック
	if movement_path.is_empty():
		print("A*パスが見つからないため直線経路を使用: ", start, " -> ", end)
		movement_path = Hex.linedraw(start, end)
	
	# 現在位置は除外（既にいるため）
	if movement_path.size() > 0 and Hex.equals(movement_path[0], start):
		movement_path.remove_at(0)
	
	# デバッグ出力
	print("計算された経路 (", movement_path.size(), "ステップ): ", movement_path)

# hex座標からピクセル座標に変換
func hex_to_pixel_position(hex_coord: Hex) -> Vector2:
	if grid_layout:
		return Layout.hex_to_pixel(grid_layout, hex_coord)
	else:
		# フォールバック: レイアウトがない場合は原点を返す
		return Vector2.ZERO

# 次の目標ピクセル座標を設定
func set_next_target_pixel():
	if next_hex_index < movement_path.size():
		var next_hex = movement_path[next_hex_index]
		current_target_pixel = hex_to_pixel_position(next_hex)

# 物理移動処理
func _physics_process(delta):
	if is_moving and movement_path.size() > 0:
		process_movement(delta)

# 移動処理の実行
func process_movement(delta):
	var distance_to_target = global_position.distance_to(current_target_pixel)
	
	# 目標に十分近づいた場合
	if distance_to_target < 5.0:
		# 次のhex位置に移動完了
		if next_hex_index < movement_path.size():
			current_hex_position = movement_path[next_hex_index]
			# プレイヤーをhexの中央に正確に配置
			update_position_to_hex_center()
			next_hex_index += 1
			
			# まだ経路が残っている場合は次の目標を設定
			if next_hex_index < movement_path.size():
				set_next_target_pixel()
			else:
				# 全経路完了 - 最終位置もhexの中央に配置
				is_moving = false
				movement_path.clear()
				update_position_to_hex_center()
	else:
		# 目標に向かって移動
		var direction = global_position.direction_to(current_target_pixel)
		velocity = direction * move_speed
		move_and_slide()