class_name BattleSession
extends RefCounted

# 隣の chunk を戦って解放しているあいだの状態。戦闘前の建築の画面へ戻るための情報も持つ。
# 戦闘を始める・終える段取り（画面やカメラの切り替え）は Main が行う

# 画面の下でスキルのボタンが占める高さと、上下左右に空ける余白（画面のピクセル）
const BOTTOM_RESERVED := 100.0
const MARGIN := 16.0
# 戦闘中に引ける限界（chunk 全体が収まる倍率の方が小さければ、そこまで）
const MIN_ZOOM := 0.5

# 戦って解放しようとしている chunk
var chunk_hex: Vector2i
# 戦闘前にいた chunk。負けたり撤退したりしたら、ここへ戻る
var return_hex: Vector2i
# 戦闘前のカメラの倍率と、引ける限界
var return_zoom: float
var return_min_zoom: float
# いまの戦闘。勝ったとき、主人公が戦い終えたマスにキャラクターを立たせるのに使う
var turn: SkillTurn = null


func _init(
	chunk_hex_val: Vector2i,
	return_hex_val: Vector2i,
	return_zoom_val: float,
	return_min_zoom_val: float
) -> void:
	chunk_hex = chunk_hex_val
	return_hex = return_hex_val
	return_zoom = return_zoom_val
	return_min_zoom = return_min_zoom_val


# 大きさ screen_size の画面で、chunk 全体がスキルのボタンに隠れずに収まるカメラ {position, zoom}。
# chunk の中心は、ボタンを除いた残りの領域の真ん中に来る（position は chunk の座標）
static func camera_view(chunk: Chunk, screen_size: Vector2) -> Dictionary:
	var cell = HexTile.visual_circumradius()
	var half_cell = Vector2(cell * sqrt(3.0) / 2.0, cell)
	var bounds := Rect2(chunk.hex_to_pixel(Vector2i(0, 0)), Vector2.ZERO)
	for hex in chunk.get_all_hexes():
		var center = chunk.hex_to_pixel(hex)
		bounds = bounds.merge(Rect2(center - half_cell, half_cell * 2.0))
	var area = screen_size - Vector2(MARGIN * 2.0, MARGIN * 2.0 + BOTTOM_RESERVED)
	# ボタンより小さい画面でも、倍率が 0 やマイナスにならないようにする
	area = area.max(Vector2.ONE)
	var zoom = minf(area.x / bounds.size.x, area.y / bounds.size.y)
	# ボタンを除いた領域の真ん中は、画面の真ん中よりボタンの高さの半分だけ上にある
	var shift = Vector2(0, BOTTOM_RESERVED / 2.0 / zoom)
	return {"position": bounds.get_center() + shift, "zoom": zoom}


# 戦闘のカメラの倍率が view_zoom のときに、引ける限界
static func min_zoom_for(view_zoom: float) -> float:
	return minf(MIN_ZOOM, view_zoom)
