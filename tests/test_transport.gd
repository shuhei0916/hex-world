extends GutTest

var grid_manager: GridManager

func before_each():
	grid_manager = GridManager.new()
	grid_manager.hex_tile_scene = preload("res://scenes/components/hex_tile/hex_tile.tscn")
	add_child_autofree(grid_manager)
	grid_manager.create_hex_grid(2)

func test_隣接するピースにアイテムが移動する():
	# 1. ピースを2つ配置
	# Piece A (BAR) at (0,0)
	grid_manager.place_piece([Hex.new(0,0)], Hex.new(0,0), Color.RED, TetrahexShapes.TetrahexType.BAR)
	var piece_a = grid_manager.get_piece_at_hex(Hex.new(0,0))
	
	# Piece B (CHEST) at (1,0)
	grid_manager.place_piece([Hex.new(0,0)], Hex.new(1,0), Color.BLUE, TetrahexShapes.TetrahexType.CHEST)
	var piece_b = grid_manager.get_piece_at_hex(Hex.new(1,0))
	
	# 2. Piece A にアイテムを持たせる
	piece_a.add_item("iron", 1)
	assert_eq(piece_a.get_item_count("iron"), 1)
	assert_eq(piece_b.get_item_count("iron"), 0)
	
	# 3. tick を実行 (移動ロジックが呼ばれるはず)
	piece_a.tick(0.1)
	
	# 4. 検証: AからBへ移動していること
	assert_eq(piece_a.get_item_count("iron"), 0, "Piece Aのインベントリは空になるべき")
	assert_eq(piece_b.get_item_count("iron"), 1, "Piece Bにアイテムが移動しているべき")
