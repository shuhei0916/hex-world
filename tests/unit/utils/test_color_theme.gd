extends GutTest

## 見た目の配色。いまの暗い見た目（ダーク）と、紙のボードゲームのような明るい見た目（ライト）を切り替える。

const SETTINGS_PATH := "user://test_color_theme_settings.cfg"


func before_each():
	ColorTheme.set_mode(ColorTheme.Mode.DARK)
	DirAccess.remove_absolute(SETTINGS_PATH)


func after_each():
	ColorTheme.set_mode(ColorTheme.Mode.DARK)
	DirAccess.remove_absolute(SETTINGS_PATH)


func test_最初はダーク():
	assert_eq(ColorTheme.mode, ColorTheme.Mode.DARK)
	assert_false(ColorTheme.is_light())


func test_切り替えるとライトになり_もう一度でダークに戻る():
	ColorTheme.toggle()
	assert_true(ColorTheme.is_light())
	ColorTheme.toggle()
	assert_false(ColorTheme.is_light())


func test_ライトでは地も床も明るい():
	var dark_floor := ColorTheme.color(&"floor")
	var dark_background := ColorTheme.color(&"background")
	ColorTheme.set_mode(ColorTheme.Mode.LIGHT)
	assert_gt(ColorTheme.color(&"floor").get_luminance(), dark_floor.get_luminance() + 0.4)
	assert_gt(
		ColorTheme.color(&"background").get_luminance(), dark_background.get_luminance() + 0.4
	)


func test_ライトでは文字は地より暗い():
	ColorTheme.set_mode(ColorTheme.Mode.LIGHT)
	assert_lt(
		ColorTheme.color(&"text").get_luminance(),
		ColorTheme.color(&"background").get_luminance() - 0.4
	)


func test_どちらの配色にも同じ名前の色がそろっている():
	assert_eq_deep(ColorTheme.LIGHT.keys(), ColorTheme.DARK.keys())


func test_切り替えると通知される():
	watch_signals(ColorTheme.notifier)
	ColorTheme.set_mode(ColorTheme.Mode.LIGHT)
	assert_signal_emitted(ColorTheme.notifier, "changed")


func test_同じ配色を選び直しても通知しない():
	watch_signals(ColorTheme.notifier)
	ColorTheme.set_mode(ColorTheme.Mode.DARK)
	assert_signal_not_emitted(ColorTheme.notifier, "changed")


func test_選んだ配色は設定ファイルに残り_次に読み込むと戻る():
	ColorTheme.set_mode(ColorTheme.Mode.LIGHT)
	ColorTheme.save_settings(SETTINGS_PATH)
	ColorTheme.set_mode(ColorTheme.Mode.DARK)
	ColorTheme.load_settings(SETTINGS_PATH)
	assert_true(ColorTheme.is_light())


func test_設定ファイルが無ければダークのまま():
	ColorTheme.load_settings(SETTINGS_PATH)
	assert_false(ColorTheme.is_light())


func test_バイオームの色はライトでは紙の色に寄せて淡くする():
	var forest := Color("#2a5a3a")
	assert_eq(ColorTheme.map_color(forest), forest, "ダークではそのまま")
	ColorTheme.set_mode(ColorTheme.Mode.LIGHT)
	assert_gt(ColorTheme.map_color(forest).get_luminance(), forest.get_luminance() + 0.2)


func test_ライトでは画面の部品に明るい部品の見た目を使い_ダークでは標準のまま():
	assert_null(ColorTheme.ui_theme())
	ColorTheme.set_mode(ColorTheme.Mode.LIGHT)
	var theme := ColorTheme.ui_theme()
	assert_not_null(theme)
	assert_eq(theme.get_color("font_color", "Label"), ColorTheme.color(&"text"))
