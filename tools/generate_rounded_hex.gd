extends SceneTree

## 角の丸い六角形の画像を作る（タイル用。白で描き、色は modulate で乗せる）。
## ローカルの床用の pointy-top と、ワールドマップ用の flat-top の2枚を同じ形で作る。
## 元の HexagonPointedTop.png と同じ 256x256 のキャンバスで、平らな辺の位置をそろえるので、
## Sprite2D の scale はそのまま差し替えられる。
##   godot --headless --script res://tools/generate_rounded_hex.gd

const SIZE := 256
const HexTileScript = preload("res://scenes/components/hex_tile/hex_tile.gd")
const CIRCUMRADIUS := HexTileScript.TEXTURE_CIRCUMRADIUS
const CORNER_RADIUS := HexTileScript.TEXTURE_CORNER_RADIUS
const OUTPUT := "res://assets/HexagonRounded.png"
const FLAT_OUTPUT := "res://assets/HexagonRoundedFlat.png"


func _init() -> void:
	_save(OUTPUT, false)
	_save(FLAT_OUTPUT, true)
	quit()


func _save(path: String, flat_top: bool) -> void:
	var img := Image.create(SIZE, SIZE, false, Image.FORMAT_RGBA8)
	var center := Vector2(SIZE, SIZE) * 0.5
	var inradius := CIRCUMRADIUS * sqrt(3.0) * 0.5
	for y in SIZE:
		for x in SIZE:
			var p := Vector2(x + 0.5, y + 0.5) - center
			var shape_p := Vector2(p.y, p.x) if flat_top else p
			var d := _rounded_hex_distance(shape_p, inradius, CORNER_RADIUS)
			var alpha := clampf(0.5 - d, 0.0, 1.0)
			img.set_pixel(x, y, Color(1, 1, 1, alpha))
	img.save_png(ProjectSettings.globalize_path(path))
	print("saved ", path)


# 角を丸めた pointy-top 六角形までの符号付き距離（内側が負）。平らな辺は inradius の位置に保つ
static func _rounded_hex_distance(p: Vector2, inradius: float, corner: float) -> float:
	# 左右が平らな辺になるよう x,y を入れ替えて、上下が平らな六角形の式を使う
	var q := Vector2(absf(p.y), absf(p.x))
	var k := Vector2(-sqrt(3.0) * 0.5, 0.5)
	var r := inradius - corner
	q -= 2.0 * minf(k.dot(q), 0.0) * k
	q -= Vector2(clampf(q.x, -r / sqrt(3.0), r / sqrt(3.0)), r)
	return q.length() * signf(q.y) - corner
