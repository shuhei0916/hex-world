extends GutTest

var button: HexButton


func before_each():
	button = HexButton.new()
	button.size = Vector2(52, 60)
	add_child_autofree(button)


func test_六角形の中心はボタンの内側():
	assert_true(button._has_point(Vector2(26, 30)))


func test_四角形の角は六角形の外なので押せない():
	assert_false(button._has_point(Vector2(1, 1)))
	assert_false(button._has_point(Vector2(51, 59)))


func test_上下のとがった先の近くは押せる():
	assert_true(button._has_point(Vector2(26, 4)))
	assert_true(button._has_point(Vector2(26, 56)))


func test_四角いボタンの枠は描かない():
	assert_true(button.flat)


func test_アイコンを持てる():
	var tex := PlaceholderTexture2D.new()
	button.hex_icon = tex
	assert_eq(button.hex_icon, tex)


func test_アイコンはダークでは白のまま_ライトではインクの色で描く():
	assert_eq(button.get_icon_color(), Color.WHITE)
	ColorTheme.set_mode(ColorTheme.Mode.LIGHT)
	assert_eq(button.get_icon_color(), ColorTheme.LIGHT[&"button_icon"])
	ColorTheme.set_mode(ColorTheme.Mode.DARK)
