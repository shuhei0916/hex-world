extends GutTest

# GridManagerのテスト
class_name TestGridManager

const GridManagerClass = preload("res://scenes/components/grid/grid_manager.gd")
var grid_manager_instance: GridManagerClass

func before_each():
	grid_manager_instance = GridManagerClass.new()
	# テスト内でHexTile.tscnへの参照を設定
	grid_manager_instance.hex_tile_scene = preload("res://scenes/components/grid/hex_tile/HexTile.tscn")
	add_child_autofree(grid_manager_instance)
	grid_manager_instance.clear_grid() # 既存のクリアロジックを呼び出す

func test_グリッドhexを登録できる():
	var hex = Hex.new(0, 0, 0)
	grid_manager_instance.register_grid_hex(hex)
	assert_true(grid_manager_instance.is_inside_grid(hex))

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
		grid_manager_instance.register_grid_hex(hex)
		assert_true(grid_manager_instance.is_inside_grid(hex))

func test_登録されていないhexはグリッド外と判定される():
	var unregistered_hex = Hex.new(10, 10, -20)
	assert_false(grid_manager_instance.is_inside_grid(unregistered_hex))

func test_hexを占有状態にできる():
	var hex = Hex.new(1, 1, -2)
	grid_manager_instance.register_grid_hex(hex)
	assert_false(grid_manager_instance.is_occupied(hex))
	
	grid_manager_instance.occupy(hex)
	assert_true(grid_manager_instance.is_occupied(hex))

func test_単一hexを配置可能か判定できる():
	var base_hex = Hex.new(2, 2, -4)
	var shape = [Hex.new(0, 0, 0)]
	
	grid_manager_instance.register_grid_hex(base_hex)
	
	assert_true(grid_manager_instance.can_place(shape, base_hex))
	
	grid_manager_instance.place_piece(shape, base_hex)
	assert_false(grid_manager_instance.can_place(shape, base_hex))

func test_複数hex形状の配置可能判定ができる():
	var base_hex = Hex.new(0, 0, 0)
	var shape = [
		Hex.new(0, 0, 0),
		Hex.new(1, 0, -1),
		Hex.new(2, 0, -2)
	]
	
	for offset in shape:
		var target = Hex.add(base_hex, offset)
		grid_manager_instance.register_grid_hex(target)
	
	assert_true(grid_manager_instance.can_place(shape, base_hex))

func test_一部がグリッド外の場合配置不可能と判定される():
	var base_hex = Hex.new(0, 0, 0)
	var shape = [
		Hex.new(0, 0, 0),
		Hex.new(1, 0, -1),
		Hex.new(-1, 0, 1)
	]
	
	grid_manager_instance.register_grid_hex(base_hex)
	grid_manager_instance.register_grid_hex(Hex.add(base_hex, Hex.new(-1, 0, 1)))
	
	assert_false(grid_manager_instance.can_place(shape, base_hex))

func test_ピースを配置できる():
	var base_hex = Hex.new(0, 0, 0)
	var shape = [
		Hex.new(0, 0, 0),
		Hex.new(1, 0, -1)
	]
	
	for offset in shape:
		var target = Hex.add(base_hex, offset)
		grid_manager_instance.register_grid_hex(target)
	
	for offset in shape:
		var target = Hex.add(base_hex, offset)
		assert_false(grid_manager_instance.is_occupied(target))
	
	grid_manager_instance.place_piece(shape, base_hex)
	
	for offset in shape:
		var target = Hex.add(base_hex, offset)
		assert_true(grid_manager_instance.is_occupied(target))

func test_ピースを解除できる():
	var base_hex = Hex.new(0, 0, 0)
	var shape = [
		Hex.new(0, 0, 0),
		Hex.new(0, 1, -1)
	]
	
	for offset in shape:
		var target = Hex.add(base_hex, offset)
		grid_manager_instance.register_grid_hex(target)
	
	grid_manager_instance.place_piece(shape, base_hex)
	
	grid_manager_instance.unplace_piece(shape, base_hex)
	
	for offset in shape:
		var target = Hex.add(base_hex, offset)
		assert_false(grid_manager_instance.is_occupied(target))

func test_グリッド状態をクリアできる():
	var hex = Hex.new(1, 1, -2)
	grid_manager_instance.register_grid_hex(hex)
	grid_manager_instance.occupy(hex)
	
	assert_true(grid_manager_instance.is_inside_grid(hex))
	assert_true(grid_manager_instance.is_occupied(hex))
	
	grid_manager_instance.clear_grid()
	
	assert_false(grid_manager_instance.is_inside_grid(hex))
	assert_false(grid_manager_instance.is_occupied(hex))