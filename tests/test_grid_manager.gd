extends GutTest

# GridManagerのテスト
class_name TestGridManager

const GridManagerClass = preload("res://scenes/components/grid/grid_manager.gd")
const Piece = preload("res://scenes/components/piece/piece.gd")
const TetrahexShapes = preload("res://scenes/utils/tetrahex_shapes.gd")
var grid_manager_instance: GridManagerClass

func before_each():
	grid_manager_instance = GridManagerClass.new()
	# テスト内でHexTile.tscnへの参照を設定
	grid_manager_instance.hex_tile_scene = preload("res://scenes/components/hex_tile/hex_tile.tscn")
	add_child_autofree(grid_manager_instance)
	grid_manager_instance.clear_grid() # 既存のクリアロジックを呼び出す

func after_each():
	await get_tree().process_frame

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
	
	grid_manager_instance.place_piece(shape, base_hex, Color.WHITE)
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
	
	grid_manager_instance.place_piece(shape, base_hex, Color.WHITE)
	
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
	
	grid_manager_instance.place_piece(shape, base_hex, Color.WHITE)
	
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

func test_ピース配置時にグリッド色がピース色に変わる():
	# グリッドを作成 (テストで利用できるように)
	grid_manager_instance.create_hex_grid(1) # 小さなグリッドで十分
	
	# 配置するピースの形状と色を定義
	var piece_shape = [Hex.new(0, 0), Hex.new(1, 0)]
	var piece_color = Color.RED # 例として赤色

	# ピースを配置
	grid_manager_instance.place_piece(piece_shape, Hex.new(0, 0), piece_color) # piece_colorも渡せるようにする
	
	# 配置後、Hexが占有されていることを確認
	for hex_offset in piece_shape:
		var target_hex = Hex.add(Hex.new(0,0), hex_offset)
		assert_true(grid_manager_instance.is_occupied(target_hex))
		
		# 配置されたHexに対応するHexTileの色が変わっていることを確認 (REDになる箇所)
		var hex_tile = grid_manager_instance.find_hex_tile(target_hex)
		assert_not_null(hex_tile, "HexTile should exist for " + target_hex.to_string())
		
		assert_eq(hex_tile.get_color(), piece_color, "HexTile color should match piece color after placement")

func test_ピースを配置するとPieceノードが生成される():
	grid_manager_instance.create_hex_grid(1)
	var shape: Array[Hex] = [Hex.new(0, 0), Hex.new(1, 0)]
	var base_hex = Hex.new(0, 0)
	var piece_color = Color.BLUE
	var piece_type = TetrahexShapes.TetrahexType.BAR
	
	# place_pieceにpiece_typeを渡す（まだ実装前だがテストでは渡しておく）
	# 実装時にシグネチャを変更する
	# GDScriptでは引数が多くてもエラーにならない場合があるが、安全のため3引数で呼んでおくか
	# いや、TDDなので「こう呼び出したい」というインターフェースを先に書くべき。
	# よって4引数で呼ぶ。
	grid_manager_instance.place_piece(shape, base_hex, piece_color, piece_type)
	
	# Pieceノードが追加されたことを確認
	var found_piece = null
	for child in grid_manager_instance.get_children():
		if child is Piece:
			found_piece = child
			break
	
	assert_not_null(found_piece, "Pieceノードが生成され、GridManagerに追加されるべき")
	if found_piece:
		assert_true(found_piece is Piece, "生成されたノードはPiece型であるべき")
		assert_eq(found_piece.piece_type, piece_type, "Pieceタイプが正しく設定されるべき")
		assert_eq(found_piece.hex_coordinates.size(), shape.size(), "Pieceの座標リストサイズが一致すべき")
		
		# 座標の確認
		var expected_pos = grid_manager_instance.hex_to_pixel(base_hex)
		assert_eq(found_piece.position, expected_pos, "Piece should be placed at correct position")
