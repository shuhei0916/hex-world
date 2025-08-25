extends GutTest

const HexCoordinate = preload("res://scripts/hex_coordinate.gd")

func test_hex_coordinate_creation():
	var hex = HexCoordinate.new(1, -1, 0)
	assert_eq(hex.q, 1, "q座標が正しく設定される")
	assert_eq(hex.r, -1, "r座標が正しく設定される")
	assert_eq(hex.s, 0, "s座標が正しく設定される")

func test_hex_coordinate_constraint():
	var hex = HexCoordinate.new(1, -1, 0)
	assert_true(hex.is_valid(), "有効な座標では制約 q + r + s = 0 が満たされる")

func test_hex_coordinate_addition():
	var hex1 = HexCoordinate.new(1, -1, 0)
	var hex2 = HexCoordinate.new(0, 1, -1)
	var result = hex1.add(hex2)
	assert_eq(result.q, 1, "加算結果のq座標が正しい")
	assert_eq(result.r, 0, "加算結果のr座標が正しい")
	assert_eq(result.s, -1, "加算結果のs座標が正しい")

func test_hex_coordinate_subtraction():
	var hex1 = HexCoordinate.new(1, -1, 0)
	var hex2 = HexCoordinate.new(0, 1, -1)
	var result = hex1.subtract(hex2)
	assert_eq(result.q, 1, "減算結果のq座標が正しい")
	assert_eq(result.r, -2, "減算結果のr座標が正しい")
	assert_eq(result.s, 1, "減算結果のs座標が正しい")

func test_hex_coordinate_scaling():
	var hex = HexCoordinate.new(1, -2, 1)
	var result = hex.scale(2)
	assert_eq(result.q, 2, "スケーリング結果のq座標が正しい")
	assert_eq(result.r, -4, "スケーリング結果のr座標が正しい")
	assert_eq(result.s, 2, "スケーリング結果のs座標が正しい")

func test_hex_coordinate_neighbor():
	var hex = HexCoordinate.new(1, -2, 1)
	var neighbor = hex.neighbor(2)
	assert_eq(neighbor.q, 1, "隣接セル(方向2:左上)のq座標が正しい")
	assert_eq(neighbor.r, -3, "隣接セル(方向2:左上)のr座標が正しい")
	assert_eq(neighbor.s, 2, "隣接セル(方向2:左上)のs座標が正しい")

func test_hex_coordinate_distance():
	var hex1 = HexCoordinate.new(3, -7, 4)
	var hex2 = HexCoordinate.new(0, 0, 0)
	var distance = hex1.distance(hex2)
	assert_eq(distance, 7, "六角形間の距離が正しく計算される")

func test_hex_diagonal_neighbor():
	var hex = HexCoordinate.new(1, -2, 1)
	var diagonal = hex.diagonal_neighbor(3)
	assert_eq(diagonal.q, -1, "対角隣接セル(方向3)のq座標が正しい")
	assert_eq(diagonal.r, -1, "対角隣接セル(方向3)のr座標が正しい")
	assert_eq(diagonal.s, 2, "対角隣接セル(方向3)のs座標が正しい")

func test_hex_to_pixel():
	var hex = HexCoordinate.new(3, 4, -7)
	var size = 10.0
	var origin = Vector2(35.0, 71.0)
	var pixel = hex.to_pixel(size, origin)
	assert_almost_eq(pixel.x, 121.602, 0.01, "hex to pixel X座標が正しい")
	assert_almost_eq(pixel.y, 131.0, 0.001, "hex to pixel Y座標が正しい")

func test_pixel_to_hex():
	var pixel = Vector2(121.602, 131.0)
	var size = 10.0
	var origin = Vector2(35.0, 71.0)
	var hex = HexCoordinate.from_pixel(pixel, size, origin)
	assert_eq(hex.q, 3, "pixel to hex q座標が正しい")
	assert_eq(hex.r, 4, "pixel to hex r座標が正しい")
	assert_eq(hex.s, -7, "pixel to hex s座標が正しい")

func test_hex_coordinate_invalid_creation():
	# Red Blob Games準拠: 無効な座標での作成を許可しない
	var invalid_hex = HexCoordinate.new(1, 1, 1)  # q + r + s = 3 ≠ 0
	assert_false(invalid_hex.is_valid(), "無効な座標(1,1,1)は is_valid() が false を返す")
	
	# より厳密なテスト: 作成時にエラーが発生することを確認
	var should_fail = HexCoordinate.create_validated(1, 2, 3)  # q + r + s = 6 ≠ 0
	assert_null(should_fail, "無効な座標での create_validated は null を返す")
	
	# 有効な座標は正常に作成される
	var valid_hex = HexCoordinate.create_validated(1, -2, 1)  # q + r + s = 0
	assert_not_null(valid_hex, "有効な座標での create_validated は座標を返す")
	assert_eq(valid_hex.q, 1, "有効座標のq値が正しい")
	assert_eq(valid_hex.r, -2, "有効座標のr値が正しい")
	assert_eq(valid_hex.s, 1, "有効座標のs値が正しい")
	