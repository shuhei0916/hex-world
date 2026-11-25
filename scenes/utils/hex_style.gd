class_name HexStyle
## マスの見た目の色と線。単色のマスを細い線で区切る。
## 色は配色（ColorTheme）から引くので、ローカル画面・ワールドマップ・戦闘のすべてが
## ダーク・ライトの切り替えに従う。

const BORDER_WIDTH := 2.0


## マスの無いところの地の色。
static func background_color() -> Color:
	return ColorTheme.color(&"background")


## 何も無い床のマス。
static func floor_color() -> Color:
	return ColorTheme.color(&"floor")


## 通れないマス（戦闘の壁）。
static func wall_color() -> Color:
	return ColorTheme.color(&"wall")


## マスとマスを区切る線。
static func border_color() -> Color:
	return ColorTheme.color(&"border")
