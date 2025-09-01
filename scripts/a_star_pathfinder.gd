class_name AStarPathfinder
extends RefCounted

# AStarPathfinder - A*アルゴリズムを使ったhex座標系パスファインディング
# redblobgames implementationを参考にGDScriptで実装

const PriorityQueue = preload("res://scripts/priority_queue.gd")
const HexGraph = preload("res://scripts/hex_graph.gd")

func _init():
	pass

# A*アルゴリズムを使ってパスを探索
func find_path(graph: HexGraph, start: Hex, goal: Hex) -> Array[Hex]:
	var frontier = PriorityQueue.new()
	frontier.put(start, 0.0)
	
	var came_from: Dictionary = {}
	var cost_so_far: Dictionary = {}
	
	var start_key = _hex_to_key(start)
	var goal_key = _hex_to_key(goal)
	
	came_from[start_key] = null
	cost_so_far[start_key] = 0.0
	
	while not frontier.empty():
		var current: Hex = frontier.pop()
		var current_key = _hex_to_key(current)
		
		if Hex.equals(current, goal):
			break
		
		for next_hex in graph.neighbors(current):
			var next_key = _hex_to_key(next_hex)
			var new_cost = cost_so_far[current_key] + _cost(current, next_hex)
			
			if not cost_so_far.has(next_key) or new_cost < cost_so_far[next_key]:
				cost_so_far[next_key] = new_cost
				var priority = new_cost + _heuristic(next_hex, goal)
				frontier.put(next_hex, priority)
				came_from[next_key] = current
	
	return _reconstruct_path(came_from, start, goal)

# Hexオブジェクトをキー文字列に変換
func _hex_to_key(hex_coord: Hex) -> String:
	return "%d,%d" % [hex_coord.q, hex_coord.r]

# 隣接ノード間の移動コスト（均一）
func _cost(from_hex: Hex, to_hex: Hex) -> float:
	return 1.0

# ヒューリスティック関数（hex座標系のマンハッタン距離）
func _heuristic(from_hex: Hex, to_hex: Hex) -> float:
	return float(Hex.distance(from_hex, to_hex))

# パスを復元する
func _reconstruct_path(came_from: Dictionary, start: Hex, goal: Hex) -> Array[Hex]:
	var goal_key = _hex_to_key(goal)
	
	# ゴールに到達できなかった場合は空のパスを返す
	if not came_from.has(goal_key):
		return []
	
	var current = goal
	var path: Array[Hex] = []
	var safety_counter = 0  # 無限ループ防止
	
	while current != null and safety_counter < 1000:
		path.append(current)
		var current_key = _hex_to_key(current)
		current = came_from.get(current_key)
		safety_counter += 1
		
		# スタートに到達したら終了
		if current != null and Hex.equals(current, start):
			path.append(current)
			break
	
	path.reverse()
	return path