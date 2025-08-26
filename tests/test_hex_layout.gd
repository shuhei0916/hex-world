extends GutTest

class_name TestHexLayout

func test_layout():
	# テストリスト項目: test_layout関数のテスト
	# Python版: Layoutでhex↔pixel変換の往復テスト
	var h = Hex.new(3, 4, -7)
	
	# flat orientation layout
	var flat = Layout.new(HexLayout.layout_flat, Vector2(10.0, 15.0), Vector2(35.0, 71.0))
	var flat_result = HexLayout.pixel_to_hex_rounded(flat, HexLayout.hex_to_pixel(flat, h))
	assert_true(Hex.equals(h, flat_result), "Layout flat orientation roundtrip should preserve hex coordinates")
	
	# pointy orientation layout
	var pointy = Layout.new(HexLayout.layout_pointy, Vector2(10.0, 15.0), Vector2(35.0, 71.0))
	var pointy_result = HexLayout.pixel_to_hex_rounded(pointy, HexLayout.hex_to_pixel(pointy, h))
	assert_true(Hex.equals(h, pointy_result), "Layout pointy orientation roundtrip should preserve hex coordinates")