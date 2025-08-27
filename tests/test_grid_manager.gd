extends GutTest

# GridManagerのテスト
class_name TestGridManager

func test_grid_manager_singleton_exists():
	# GridManagerがシングルトンとして存在するか
	assert_not_null(GridManager)

func test_register_grid_hex():
	# グリッドのhexを登録できるか
	var hex = Hex.new(0, 0, 0)
	GridManager.register_grid_hex(hex)
	assert_true(GridManager.is_inside_grid(hex))

func test_multiple_grid_hex_registration():
	# 複数のhexを登録できるか
	var hexes = [
		Hex.new(0, 0, 0),
		Hex.new(1, 0, -1),
		Hex.new(0, 1, -1),
		Hex.new(-1, 1, 0),
		Hex.new(-1, 0, 1),
		Hex.new(0, -1, 1)
	]
	
	for hex in hexes:
		GridManager.register_grid_hex(hex)
		assert_true(GridManager.is_inside_grid(hex))

func test_is_inside_grid_false_for_unregistered():
	# 登録されていないhexはグリッド外
	var unregistered_hex = Hex.new(10, 10, -20)
	assert_false(GridManager.is_inside_grid(unregistered_hex))

func test_occupy_hex():
	# hexを占有できるか
	var hex = Hex.new(1, 1, -2)
	GridManager.register_grid_hex(hex)
	assert_false(GridManager.is_occupied(hex))
	
	GridManager.occupy(hex)
	assert_true(GridManager.is_occupied(hex))

func test_can_place_single_hex():
	# 単一のhexを配置可能か判定できるか
	var base_hex = Hex.new(2, 2, -4)
	var shape = [Hex.new(0, 0, 0)]
	
	# グリッドに登録
	GridManager.register_grid_hex(base_hex)
	
	# 配置可能
	assert_true(GridManager.can_place(shape, base_hex))
	
	# 占有後は配置不可能
	GridManager.place_piece(shape, base_hex)
	assert_false(GridManager.can_place(shape, base_hex))

func test_can_place_multiple_hex_shape():
	# 複数hexからなる形状の配置可能判定
	var base_hex = Hex.new(0, 0, 0)
	var shape = [
		Hex.new(0, 0, 0),
		Hex.new(1, 0, -1),
		Hex.new(2, 0, -2)
	]
	
	# 必要なグリッドを登録
	for offset in shape:
		var target = Hex.add(base_hex, offset)
		GridManager.register_grid_hex(target)
	
	# 配置可能
	assert_true(GridManager.can_place(shape, base_hex))

func test_can_place_fails_when_partially_outside_grid():
	# 一部がグリッド外の場合配置不可能
	var base_hex = Hex.new(0, 0, 0)
	var shape = [
		Hex.new(0, 0, 0),
		Hex.new(1, 0, -1),  # これはグリッド外
		Hex.new(-1, 0, 1)
	]
	
	# base_hexとoffset(-1, 0, 1)のみ登録
	GridManager.register_grid_hex(base_hex)
	GridManager.register_grid_hex(Hex.add(base_hex, Hex.new(-1, 0, 1)))
	
	# (1, 0, -1)はグリッド外なので配置不可能
	assert_false(GridManager.can_place(shape, base_hex))

func test_place_piece():
	# ピースを配置できるか
	var base_hex = Hex.new(0, 0, 0)
	var shape = [
		Hex.new(0, 0, 0),
		Hex.new(1, 0, -1)
	]
	
	# 必要なグリッドを登録
	for offset in shape:
		var target = Hex.add(base_hex, offset)
		GridManager.register_grid_hex(target)
	
	# 配置前は占有されていない
	for offset in shape:
		var target = Hex.add(base_hex, offset)
		assert_false(GridManager.is_occupied(target))
	
	# 配置実行
	GridManager.place_piece(shape, base_hex)
	
	# 配置後は占有されている
	for offset in shape:
		var target = Hex.add(base_hex, offset)
		assert_true(GridManager.is_occupied(target))

func test_unplace_piece():
	# ピースを解除できるか
	var base_hex = Hex.new(0, 0, 0)
	var shape = [
		Hex.new(0, 0, 0),
		Hex.new(0, 1, -1)
	]
	
	# 必要なグリッドを登録
	for offset in shape:
		var target = Hex.add(base_hex, offset)
		GridManager.register_grid_hex(target)
	
	# 配置して占有状態にする
	GridManager.place_piece(shape, base_hex)
	
	# 解除実行
	GridManager.unplace_piece(shape, base_hex)
	
	# 解除後は占有されていない
	for offset in shape:
		var target = Hex.add(base_hex, offset)
		assert_false(GridManager.is_occupied(target))

func test_clear_grid_state():
	# テスト間でのグリッド状態をクリア
	# まず何かを登録して占有する
	var hex = Hex.new(1, 1, -2)
	GridManager.register_grid_hex(hex)
	GridManager.occupy(hex)
	
	# 登録と占有を確認
	assert_true(GridManager.is_inside_grid(hex))
	assert_true(GridManager.is_occupied(hex))
	
	# クリア実行
	GridManager.clear_grid()
	
	# クリア後は何も登録・占有されていない
	assert_false(GridManager.is_inside_grid(hex))
	assert_false(GridManager.is_occupied(hex))

# 各テスト前にグリッド状態をクリア
func before_each():
	if GridManager:
		GridManager.clear_grid()