extends Node

# PieceSpawner - ピース生成システム
# Unity版のPieceSpawner.csをGodotに移植

var spawn_positions: Array[Vector3] = []
var spawned_pieces: Dictionary = {}  # Vector3 -> Node の辞書

func _ready():
	print("PieceSpawner initialized")
	_initialize_spawn_positions()

func _initialize_spawn_positions():
	# Unity版と同様のスポーン位置
	spawn_positions = [
		Vector3(6, 3, 0),
		Vector3(6, 0, 0), 
		Vector3(6, -3, 0)
	]

# ランダムなTetrahexタイプを取得
func get_random_tetrahex_type():
	var types = TetrahexShapes.TetrahexType.values()
	return types[randi() % types.size()]

# スポーン位置のリストを取得
func get_spawn_positions() -> Array[Vector3]:
	return spawn_positions

# 指定位置にピースをスポーン
func spawn_piece_at_position(position: Vector3) -> Node:
	var random_type = get_random_tetrahex_type()
	var definition = TetrahexShapes.TetrahexData.definitions[random_type]
	
	# TODO: 実際のPieceノードを作成する（Pieceクラス実装後）
	# 現在はプレースホルダとしてNodeを返す
	var piece_node = Node.new()
	piece_node.name = "Piece_" + str(random_type)
	
	spawned_pieces[position] = piece_node
	return piece_node

# スポーン位置が占有されているかチェック
func is_spawn_point_occupied(position: Vector3) -> bool:
	return spawned_pieces.has(position) and spawned_pieces[position] != null

# スポーン位置をクリア
func clear_spawn_point(position: Vector3):
	if spawned_pieces.has(position):
		var piece = spawned_pieces[position]
		if piece != null:
			piece.queue_free()
		spawned_pieces.erase(position)

# 全スポーン位置をクリア（テスト用）
func clear_all_spawn_points():
	for pos in spawned_pieces.keys():
		clear_spawn_point(pos)