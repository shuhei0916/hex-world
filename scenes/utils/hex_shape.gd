class_name HexShape
## マスの形（角のとがった六角形）と、その描き方。
## ローカル画面・ワールドマップ・戦闘のどのマスも、ここを通して同じ見た目で描く。


## center を中心に、頂点までの距離が circumradius の六角形の頂点を返す。
## pointy が true なら頂点が上、false なら辺が上を向く。
static func corners(center: Vector2, circumradius: float, pointy: bool) -> PackedVector2Array:
	var offset := -30.0 if pointy else 0.0
	var result := PackedVector2Array()
	for i in range(6):
		result.append(center + Vector2.from_angle(deg_to_rad(60.0 * i + offset)) * circumradius)
	return result


## 線で描くための輪郭。頂点を一周して最初の頂点に戻る。
static func outline(center: Vector2, circumradius: float, pointy: bool) -> PackedVector2Array:
	var result := corners(center, circumradius, pointy)
	result.append(result[0])
	return result


## canvas の _draw の中で呼び、fill で塗った六角形を細い線で縁取って描く。
static func draw(
	canvas: CanvasItem, center: Vector2, circumradius: float, pointy: bool, fill: Color
) -> void:
	canvas.draw_colored_polygon(corners(center, circumradius, pointy), fill)
	var border := Color(HexStyle.BORDER_COLOR, HexStyle.BORDER_COLOR.a * fill.a)
	canvas.draw_polyline(outline(center, circumradius, pointy), border, HexStyle.BORDER_WIDTH)
