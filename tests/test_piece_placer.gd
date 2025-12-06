extends GutTest

class_name TestPiecePlacer

const PiecePlacerScript = preload("res://scenes/components/piece_placer/piece_placer.gd")
const GridManagerScript = preload("res://scenes/components/grid/grid_manager.gd")
const PaletteScript = preload("res://scenes/ui/palette/palette.gd")
const HexTileScene = preload("res://scenes/components/hex_tile/hex_tile.tscn")

var piece_placer
var grid_manager
var palette

func before_each():
	grid_manager = GridManagerScript.new()
	# GridManagerの依存関係設定
	grid_manager.hex_tile_scene = HexTileScene
	add_child_autofree(grid_manager)
	grid_manager.create_hex_grid(2)
	
	palette = PaletteScript.new()
	
	piece_placer = PiecePlacerScript.new()
	add_child_autofree(piece_placer)
	piece_placer.setup(grid_manager, palette)

func test_指定したHexに選択中のピースを配置できる():
	# ピースを選択
	palette.select_slot(0) # BARピースを選択
	
	var target_hex = Hex.new(0, 0)
	
	# 配置
	var result = piece_placer.place_piece_at_hex(target_hex)
	assert_true(result, "Should return true on success")
	
	# 確認
	var piece_data = palette.get_piece_data_for_slot(0)
	for offset in piece_data["shape"]:
		var h = Hex.add(target_hex, offset)
		assert_true(grid_manager.is_occupied(h))

func test_ピース回転処理が正しい形状を返す():
	palette.select_slot(0)
	var initial_shape = palette.get_piece_data_for_slot(0).shape
	print(initial_shape)
	
	# privateメソッドだがテスト対象として呼び出す
	var rotated = piece_placer._get_rotated_piece_shape(initial_shape)
	
	var expected = []
	for h in initial_shape:
		expected.append(Hex.rotate_right(h))
		
	assert_eq(rotated.size(), expected.size())
	for i in range(expected.size()):
		assert_true(Hex.equals(rotated[i], expected[i]))

func test_回転メソッドを呼ぶと現在の形状が更新される():
	palette.select_slot(0)
	var initial_shape = piece_placer.current_piece_shape.duplicate()
	
	piece_placer.rotate_current_piece()
	
	var current_shape = piece_placer.current_piece_shape
	
	assert_eq(current_shape.size(), initial_shape.size())
	# 1回回転した形状と一致するか
	var expected = []
	for h in initial_shape:
		expected.append(Hex.rotate_right(h))
		
	for i in range(expected.size()):
		assert_true(Hex.equals(current_shape[i], expected[i]))
