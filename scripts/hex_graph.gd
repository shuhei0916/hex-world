class_name HexGraph
extends RefCounted

# HexGraph - hex座標系でのPathfinding用Graph実装
# redblobgames SquareGridのhex版

var obstacles: Dictionary = {}  # 障害物の座標をキーとして保存
var grid_radius: int = -1  # グリッドの半径（-1は無制限）

func _init():
	pass

# hex座標系での隣接ノードを取得
func neighbors(hex_coord: Hex) -> Array[Hex]:
	var result: Array[Hex] = []
	
	# hex座標系の6方向の隣接座標を取得
	for direction in range(6):
		var neighbor_hex = Hex.neighbor(hex_coord, direction)
		
		# グリッド境界内チェック
		if grid_radius >= 0 and not in_bounds(neighbor_hex):
			continue
			
		# 障害物チェック
		if is_obstacle(neighbor_hex):
			continue
			
		result.append(neighbor_hex)
	
	return result

# グリッドの境界を設定
func set_bounds(radius: int):
	grid_radius = radius

# hex座標がグリッド境界内にあるかチェック
func in_bounds(hex_coord: Hex) -> bool:
	if grid_radius < 0:
		return true  # 無制限の場合は常にtrue
	
	# 六角形グリッドの境界チェック
	var distance_from_center = Hex.distance(hex_coord, Hex.new(0, 0))
	return distance_from_center <= grid_radius

# 障害物を追加
func add_obstacle(hex_coord: Hex):
	var key = "%d,%d" % [hex_coord.q, hex_coord.r]
	obstacles[key] = true

# 障害物を削除
func remove_obstacle(hex_coord: Hex):
	var key = "%d,%d" % [hex_coord.q, hex_coord.r]
	obstacles.erase(key)

# hex座標が障害物かチェック
func is_obstacle(hex_coord: Hex) -> bool:
	var key = "%d,%d" % [hex_coord.q, hex_coord.r]
	return obstacles.has(key)

# グリッドをクリア
func clear_obstacles():
	obstacles.clear()
