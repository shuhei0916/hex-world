class_name HexStyle
## マスの見た目の色と線。暗い地に、単色のマスを細い線で区切る。
## 色を変えたくなったらここだけ直せば、ローカル画面・ワールドマップ・戦闘のすべてに効く。

## マスの無いところの地の色。
const BACKGROUND_COLOR := Color("#14161b")
## 何も無い床のマス。
const FLOOR_COLOR := Color(0.24, 0.27, 0.32)
## 通れないマス（戦闘の壁）。
const WALL_COLOR := Color(0.09, 0.1, 0.12)
## マスとマスを区切る線。
const BORDER_COLOR := Color(0.05, 0.06, 0.08)
const BORDER_WIDTH := 2.0
