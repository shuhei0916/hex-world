extends GutTest

# PieceSpawnerのテスト
class_name TestPieceSpawner

func test_piece_spawner_singleton_exists():
	assert_not_null(PieceSpawner)

func test_get_random_tetrahex_type():
	var random_type = PieceSpawner.get_random_tetrahex_type()
	var valid_types = TetrahexShapes.TetrahexType.values()
	assert_true(random_type in valid_types)

func test_spawn_positions_initialized():
	var positions = PieceSpawner.get_spawn_positions()
	assert_true(positions.size() > 0)

func test_spawn_piece_at_position():
	var positions = PieceSpawner.get_spawn_positions()
	if positions.size() > 0:
		var piece = PieceSpawner.spawn_piece_at_position(positions[0])
		assert_not_null(piece)

func test_clear_spawn_point():
	var positions = PieceSpawner.get_spawn_positions()
	if positions.size() > 0:
		PieceSpawner.clear_spawn_point(positions[0])
		assert_false(PieceSpawner.is_spawn_point_occupied(positions[0]))

func before_each():
	if PieceSpawner:
		PieceSpawner.clear_all_spawn_points()