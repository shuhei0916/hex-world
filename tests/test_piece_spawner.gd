extends GutTest

# PieceSpawnerのテスト
class_name TestPieceSpawner

func test_PieceSpawnerシングルトンが存在する():
	assert_not_null(PieceSpawner)

func test_ランダムなテトラヘックスタイプを取得できる():
	var random_type = PieceSpawner.get_random_tetrahex_type()
	var valid_types = TetrahexShapes.TetrahexType.values()
	assert_true(random_type in valid_types)

func test_スポーン位置が初期化されている():
	var positions = PieceSpawner.get_spawn_positions()
	assert_true(positions.size() > 0)

func test_指定位置にピースをスポーンできる():
	var positions = PieceSpawner.get_spawn_positions()
	if positions.size() > 0:
		var piece = PieceSpawner.spawn_piece_at_position(positions[0])
		assert_not_null(piece)

func test_スポーンポイントをクリアできる():
	var positions = PieceSpawner.get_spawn_positions()
	if positions.size() > 0:
		PieceSpawner.clear_spawn_point(positions[0])
		assert_false(PieceSpawner.is_spawn_point_occupied(positions[0]))

func before_each():
	if PieceSpawner:
		PieceSpawner.clear_all_spawn_points()
