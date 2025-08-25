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

func test_hex_rotate_left():
	# Red Blob Games準拠: rotate_left(Hex(1, -3, 2)) → Hex(-2, -1, 3)
	var hex = HexCoordinate.new(1, -3, 2)
	var rotated = hex.rotate_left()
	assert_eq(rotated.q, -2, "左回転後のq座標が正しい")
	assert_eq(rotated.r, -1, "左回転後のr座標が正しい")
	assert_eq(rotated.s, 3, "左回転後のs座標が正しい")

func test_hex_rotate_right():
	# Red Blob Games準拠: rotate_right(Hex(1, -3, 2)) → Hex(3, -2, -1)
	var hex = HexCoordinate.new(1, -3, 2)
	var rotated = hex.rotate_right()
	assert_eq(rotated.q, 3, "右回転後のq座標が正しい")
	assert_eq(rotated.r, -2, "右回転後のr座標が正しい")
	assert_eq(rotated.s, -1, "右回転後のs座標が正しい")

func test_hex_direction():
	# Red Blob Games準拠: hex_direction(2) → Hex(0, -1, 1)
	var direction_vec = HexCoordinate.direction(2)
	assert_eq(direction_vec.q, 0, "方向2(左上)のq座標が正しい")
	assert_eq(direction_vec.r, -1, "方向2(左上)のr座標が正しい")
	assert_eq(direction_vec.s, 1, "方向2(左上)のs座標が正しい")

func test_hex_lerp():
	# Red Blob Games準拠: hex_lerp(Hex(0,0,0), Hex(10,-20,10), 0.5) → Hex(5,-10,5)
	var hex_a = HexCoordinate.new(0, 0, 0)
	var hex_b = HexCoordinate.new(10, -20, 10)
	var lerped = HexCoordinate.lerp(hex_a, hex_b, 0.5)
	assert_almost_eq(lerped.q, 5.0, 0.001, "線形補間のq座標が正しい")
	assert_almost_eq(lerped.r, -10.0, 0.001, "線形補間のr座標が正しい")
	assert_almost_eq(lerped.s, 5.0, 0.001, "線形補間のs座標が正しい")

func test_hex_line_draw():
	# Red Blob Games準拠: hex_linedraw(Hex(0,0,0), Hex(1,-5,4)) → 
	# [Hex(0,0,0), Hex(0,-1,1), Hex(0,-2,2), Hex(1,-3,2), Hex(1,-4,3), Hex(1,-5,4)]
	var hex_a = HexCoordinate.new(0, 0, 0)
	var hex_b = HexCoordinate.new(1, -5, 4)
	var line = HexCoordinate.line_draw(hex_a, hex_b)
	assert_eq(line.size(), 6, "線描画の点数が正しい")
	
	# 各点をチェック
	assert_eq(line[0].q, 0, "線上の点0のq座標が正しい")
	assert_eq(line[0].r, 0, "線上の点0のr座標が正しい")
	assert_eq(line[0].s, 0, "線上の点0のs座標が正しい")
	
	assert_eq(line[1].q, 0, "線上の点1のq座標が正しい")
	assert_eq(line[1].r, -1, "線上の点1のr座標が正しい")
	assert_eq(line[1].s, 1, "線上の点1のs座標が正しい")
	
	assert_eq(line[5].q, 1, "線上の点5のq座標が正しい")
	assert_eq(line[5].r, -5, "線上の点5のr座標が正しい")
	assert_eq(line[5].s, 4, "線上の点5のs座標が正しい")

func test_hex_round_comprehensive():
	# Red Blob Games準拠: test_hex_round の完全実装
	var a = HexCoordinate.new(0, 0, 0)
	var b = HexCoordinate.new(1, -1, 0)
	var c = HexCoordinate.new(0, -1, 1)
	
	# テスト1: 基本丸め処理
	var lerped = HexCoordinate.lerp(HexCoordinate.new(0, 0, 0), HexCoordinate.new(10, -20, 10), 0.5)
	var rounded = HexCoordinate.hex_round_fractional(lerped)
	assert_eq(rounded.q, 5, "基本丸め処理のq座標が正しい")
	assert_eq(rounded.r, -10, "基本丸め処理のr座標が正しい")
	assert_eq(rounded.s, 5, "基本丸め処理のs座標が正しい")
	
	# テスト2-3: 境界値テスト
	var lerp_low = HexCoordinate.lerp(a, b, 0.499)
	var round_low = HexCoordinate.hex_round_fractional(lerp_low)
	assert_eq(round_low.q, a.q, "境界値(0.499)でのq座標が正しい")
	assert_eq(round_low.r, a.r, "境界値(0.499)でのr座標が正しい")
	assert_eq(round_low.s, a.s, "境界値(0.499)でのs座標が正しい")
	
	var lerp_high = HexCoordinate.lerp(a, b, 0.501)
	var round_high = HexCoordinate.hex_round_fractional(lerp_high)
	assert_eq(round_high.q, b.q, "境界値(0.501)でのq座標が正しい")
	assert_eq(round_high.r, b.r, "境界値(0.501)でのr座標が正しい")
	assert_eq(round_high.s, b.s, "境界値(0.501)でのs座標が正しい")
	
	# テスト4-5: 重み付き平均のテスト
	var weighted1 = HexCoordinate.HexFractional.new(
		a.q * 0.4 + b.q * 0.3 + c.q * 0.3,
		a.r * 0.4 + b.r * 0.3 + c.r * 0.3,
		a.s * 0.4 + b.s * 0.3 + c.s * 0.3
	)
	var round_w1 = HexCoordinate.hex_round_fractional(weighted1)
	assert_eq(round_w1.q, a.q, "重み付き平均1のq座標が正しい")
	assert_eq(round_w1.r, a.r, "重み付き平均1のr座標が正しい")
	assert_eq(round_w1.s, a.s, "重み付き平均1のs座標が正しい")
	
	var weighted2 = HexCoordinate.HexFractional.new(
		a.q * 0.3 + b.q * 0.3 + c.q * 0.4,
		a.r * 0.3 + b.r * 0.3 + c.r * 0.4,
		a.s * 0.3 + b.s * 0.3 + c.s * 0.4
	)
	var round_w2 = HexCoordinate.hex_round_fractional(weighted2)
	assert_eq(round_w2.q, c.q, "重み付き平均2のq座標が正しい")
	assert_eq(round_w2.r, c.r, "重み付き平均2のr座標が正しい")
	assert_eq(round_w2.s, c.s, "重み付き平均2のs座標が正しい")
	