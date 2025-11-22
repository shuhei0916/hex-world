extends GutTest

# GridManagerのテスト
class_name TestGridManager

func test_GridManagerシングルトンが存在する():
	assert_not_null(GridManager)

func test_グリッドhexを登録できる():
	var hex = Hex.new(0, 0, 0)
	GridManager.register_grid_hex(hex)
	assert_true(GridManager.is_inside_grid(hex))

func test_複数のhexを登録できる():
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

func test_登録されていないhexはグリッド外と判定される():
	var unregistered_hex = Hex.new(10, 10, -20)
	assert_false(GridManager.is_inside_grid(unregistered_hex))

func test_hexを占有状態にできる():
	var hex = Hex.new(1, 1, -2)
	GridManager.register_grid_hex(hex)
	assert_false(GridManager.is_occupied(hex))
	
	GridManager.occupy(hex)
	assert_true(GridManager.is_occupied(hex))

func test_単一hexを配置可能か判定できる():
	var base_hex = Hex.new(2, 2, -4)
	var shape = [Hex.new(0, 0, 0)]
	
	GridManager.register_grid_hex(base_hex)
	
	assert_true(GridManager.can_place(shape, base_hex))
	
	GridManager.place_piece(shape, base_hex)
	assert_false(GridManager.can_place(shape, base_hex))

func test_複数hex形状の配置可能判定ができる():
	var base_hex = Hex.new(0, 0, 0)
	var shape = [
		Hex.new(0, 0, 0),
		Hex.new(1, 0, -1),
		Hex.new(2, 0, -2)
	]
	
	for offset in shape:
		var target = Hex.add(base_hex, offset)
		GridManager.register_grid_hex(target)
	
	assert_true(GridManager.can_place(shape, base_hex))

func test_一部がグリッド外の場合配置不可能と判定される():
	var base_hex = Hex.new(0, 0, 0)
	var shape = [
		Hex.new(0, 0, 0),
		Hex.new(1, 0, -1),
		Hex.new(-1, 0, 1)
	]
	
	GridManager.register_grid_hex(base_hex)
	GridManager.register_grid_hex(Hex.add(base_hex, Hex.new(-1, 0, 1)))
	
	assert_false(GridManager.can_place(shape, base_hex))

func test_ピースを配置できる():
	var base_hex = Hex.new(0, 0, 0)
	var shape = [
		Hex.new(0, 0, 0),
		Hex.new(1, 0, -1)
	]
	
	for offset in shape:
		var target = Hex.add(base_hex, offset)
		GridManager.register_grid_hex(target)
	
	for offset in shape:
		var target = Hex.add(base_hex, offset)
		assert_false(GridManager.is_occupied(target))
	
	GridManager.place_piece(shape, base_hex)
	
	for offset in shape:
		var target = Hex.add(base_hex, offset)
		assert_true(GridManager.is_occupied(target))

func test_ピースを解除できる():
	var base_hex = Hex.new(0, 0, 0)
	var shape = [
		Hex.new(0, 0, 0),
		Hex.new(0, 1, -1)
	]
	
	for offset in shape:
		var target = Hex.add(base_hex, offset)
		GridManager.register_grid_hex(target)
	
	GridManager.place_piece(shape, base_hex)
	
	GridManager.unplace_piece(shape, base_hex)
	
	for offset in shape:
		var target = Hex.add(base_hex, offset)
		assert_false(GridManager.is_occupied(target))

func test_グリッド状態をクリアできる():
	var hex = Hex.new(1, 1, -2)
	GridManager.register_grid_hex(hex)
	GridManager.occupy(hex)
	
	assert_true(GridManager.is_inside_grid(hex))
	assert_true(GridManager.is_occupied(hex))
	
	GridManager.clear_grid()
	
	assert_false(GridManager.is_inside_grid(hex))
	assert_false(GridManager.is_occupied(hex))

func before_each():
	if GridManager:
		GridManager.clear_grid()
