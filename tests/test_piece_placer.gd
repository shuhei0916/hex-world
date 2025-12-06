extends GutTest

class_name TestPiecePlacer

const PiecePlacerScript = preload("res://scenes/components/piece_placer/piece_placer.gd")
const GridManagerScript = preload("res://scenes/components/grid/grid_manager.gd")
const PaletteScript = preload("res://scenes/ui/palette/palette.gd")
const HexTileScene = preload("res://scenes/components/hex_tile/hex_tile.tscn")

var piece_placer
var grid_manager
var palette

var shape_arch: Array[Hex]
var shape_arch_rotated: Array[Hex]

func before_all():
	shape_arch = [
		Hex.new(0, -1, 1), 
		Hex.new(1, -1, 0), 
		Hex.new(1, 0, -1), 
		Hex.new(0, 1, -1)
	]
	shape_arch_rotated = [
		Hex.new(1, -1, 0),
		Hex.new(1, 0, -1),
		Hex.new(0, 1, -1),
		Hex.new(-1, 1, 0)
	]


func before_each():
	grid_manager = GridManagerScript.new()
	# GridManagerの依存関係設定
	grid_manager.hex_tile_scene = HexTileScene
	add_child_autofree(grid_manager)
	grid_manager.create_hex_grid(2)
	
	palette = PaletteScript.new()
	add_child_autofree(palette) # paletteも自動解放対象に追加
	
	piece_placer = PiecePlacerScript.new()
	add_child_autofree(piece_placer)
	piece_placer.setup(grid_manager, palette)


func after_each():
	await get_tree().process_frame


func test_指定したHexに選択中のピースを配置できる():
	palette.select_slot(0) # BARピースを選択
	
	var target_hex = Hex.new(0, 0)
	
	var result = piece_placer.place_piece_at_hex(target_hex)
	assert_true(result, "Should return true on success")
	
	var piece_data = palette.get_piece_data_for_slot(0)
	for offset in piece_data["shape"]:
		var h = Hex.add(target_hex, offset)
		assert_true(grid_manager.is_occupied(h))


func test_ピース回転処理が正しい形状を返す():
	var rotated = piece_placer._get_rotated_piece_shape(shape_arch)
	
	assert_eq(rotated.size(), shape_arch_rotated.size(), "Rotated shape size mismatch")
	for i in range(shape_arch_rotated.size()):
		assert_true(Hex.equals(rotated[i], shape_arch_rotated[i]), 
			"Rotated hex at index %d should be %s but was %s" % [i, str(shape_arch_rotated[i]), str(rotated[i])])


func test_回転メソッドを呼ぶと現在の形状が更新される():
	piece_placer.current_piece_shape = shape_arch
	piece_placer.rotate_current_piece()
	var current_shape = piece_placer.current_piece_shape
	assert_eq(current_shape.size(), shape_arch_rotated.size())
	for i in range(shape_arch_rotated.size()):
		assert_true(Hex.equals(current_shape[i], shape_arch_rotated[i]), "Rotated hex at index %d should be correct" % i)


func test_指定した座標のピースを削除できる():
	grid_manager.create_hex_grid(2)
	var target_hex = Hex.new(0, 0)
	
	palette.select_slot(0)
	piece_placer.place_piece_at_hex(target_hex)
	
	assert_true(grid_manager.is_occupied(target_hex), "Hex should be occupied")
	
	var result = piece_placer.remove_piece_at_hex(target_hex)
	assert_true(result, "Remove should return true")
	
	assert_false(grid_manager.is_occupied(target_hex), "Hex should be empty")
	
	var piece_data = palette.get_piece_data_for_slot(0)
	for offset in piece_data["shape"]:
		var h = Hex.add(target_hex, offset)
		assert_false(grid_manager.is_occupied(h), "All parts of piece should be removed")
