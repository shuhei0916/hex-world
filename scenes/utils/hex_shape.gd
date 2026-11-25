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


## 複数のマス（角が上を向く形）を合わせた形の外周。隣のマスと共有する辺を除き、
## 残った辺を順にたどった頂点を返す（最初の頂点には戻らない）。マスは一続きで、穴が無いこと。
static func union_outline(layout: Layout, hexes: Array) -> PackedVector2Array:
	var radius: float = layout.size.x
	# 外周の辺を「始点 → 終点」でつなぐ。頂点は丸めた座標をキーにして突き合わせる
	var next_of := {}
	var point_of := {}
	for hex in hexes:
		var center := Layout.hex_to_pixel(layout, hex)
		var hex_corners := corners(center, radius, true)
		for i in range(6):
			var start := hex_corners[i]
			var end := hex_corners[(i + 1) % 6]
			var across := Layout.pixel_to_hex_rounded(layout, start + end - center)
			if across in hexes:
				continue
			next_of[_point_key(start)] = _point_key(end)
			point_of[_point_key(start)] = start
	var result := PackedVector2Array()
	if next_of.is_empty():
		return result
	var first: Vector2i = next_of.keys()[0]
	var key := first
	while true:
		result.append(point_of[key])
		key = next_of[key]
		if key == first or result.size() > next_of.size():
			break
	return result


static func _point_key(point: Vector2) -> Vector2i:
	return Vector2i((point * 100.0).round())


## canvas の _draw の中で呼び、fill で塗った六角形を細い線で縁取って描く。
static func draw(
	canvas: CanvasItem, center: Vector2, circumradius: float, pointy: bool, fill: Color
) -> void:
	canvas.draw_colored_polygon(corners(center, circumradius, pointy), fill)
	var line := HexStyle.border_color()
	var border := Color(line, line.a * fill.a)
	canvas.draw_polyline(outline(center, circumradius, pointy), border, HexStyle.BORDER_WIDTH)
