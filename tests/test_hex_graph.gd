extends GutTest

# HexGraph - 動作するドキュメント  
# hex座標系でのpathfinding用Graph実装
class_name TestHexGraph

const HexGraph = preload("res://scripts/hex_graph.gd")

var hex_graph: HexGraph

func before_each():
	hex_graph = HexGraph.new()

func after_each():
	hex_graph = null

func test_HexGraphクラスが正しく初期化される():
	assert_not_null(hex_graph)
	assert_true(hex_graph is HexGraph)

func test_hex座標の隣接ノードを取得できる():
	var center_hex = Hex.new(0, 0)
	var neighbors = hex_graph.neighbors(center_hex)
	
	# 六角形座標系では6個の隣接ノードがある
	assert_eq(neighbors.size(), 6)
	
	# 隣接ノードが正しい座標であることを確認
	var expected_neighbors = [
		Hex.new(1, 0), Hex.new(1, -1), Hex.new(0, -1),
		Hex.new(-1, 0), Hex.new(-1, 1), Hex.new(0, 1)
	]
	
	for expected_neighbor in expected_neighbors:
		var found = false
		for actual_neighbor in neighbors:
			if Hex.equals(actual_neighbor, expected_neighbor):
				found = true
				break
		assert_true(found, "Expected neighbor %s not found" % [expected_neighbor])

func test_障害物があるhex座標は隣接ノードから除外される():
	# 障害物を設定
	var blocked_hex = Hex.new(1, 0)
	hex_graph.add_obstacle(blocked_hex)
	
	var center_hex = Hex.new(0, 0)
	var neighbors = hex_graph.neighbors(center_hex)
	
	# 障害物は隣接ノードから除外される
	assert_eq(neighbors.size(), 5)
	
	# 障害物が含まれていないことを確認
	for neighbor in neighbors:
		assert_false(Hex.equals(neighbor, blocked_hex), "Obstacle should not be in neighbors")

func test_グリッド境界外のhex座標は隣接ノードから除外される():
	# 小さなグリッドを設定（半径1）
	hex_graph.set_bounds(1)
	
	# 境界近くのhex座標での隣接ノード取得
	var edge_hex = Hex.new(1, 0)  # グリッド端
	var neighbors = hex_graph.neighbors(edge_hex)
	
	# グリッド外の座標は除外される
	for neighbor in neighbors:
		assert_true(hex_graph.in_bounds(neighbor), "Neighbor should be within bounds")