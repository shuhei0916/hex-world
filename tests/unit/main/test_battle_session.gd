# 戦って chunk を解放するあいだの状態と、戦闘用のカメラ
extends GutTest

const SCREEN_SIZE := Vector2(1280, 720)

var chunk: Chunk


func before_each():
	chunk = Chunk.new()
	add_child_autofree(chunk)


func _chunk_bounds() -> Rect2:
	var bounds := Rect2(chunk.hex_to_pixel(Vector2i(0, 0)), Vector2.ZERO)
	for hex in chunk.get_all_hexes():
		bounds = bounds.expand(chunk.hex_to_pixel(hex))
	return bounds


func test_chunk全体がスキルのボタンに隠れずに画面に収まるカメラ():
	var view = BattleSession.camera_view(chunk, SCREEN_SIZE)
	var zoom: float = view["zoom"]
	var half = SCREEN_SIZE / 2.0 / zoom
	var visible = Rect2(view["position"] - half, half * 2.0)
	visible.size.y -= BattleSession.BOTTOM_RESERVED / zoom
	assert_true(visible.encloses(_chunk_bounds()), "%s に %s が収まる" % [visible, _chunk_bounds()])
	assert_gt(
		_chunk_bounds().size.y * zoom,
		(SCREEN_SIZE.y - BattleSession.BOTTOM_RESERVED) * 0.8,
		"小さすぎない"
	)


func test_ボタンより小さい画面でも倍率は正():
	var view = BattleSession.camera_view(chunk, Vector2(10, 10))
	assert_gt(view["zoom"], 0.0)


func test_戦闘中に引ける限界はchunk全体が収まる倍率よりは小さくしない():
	assert_eq(BattleSession.min_zoom_for(0.3), 0.3)
	assert_eq(BattleSession.min_zoom_for(2.0), BattleSession.MIN_ZOOM)


func test_戦いに行くchunkと戦闘前に戻る状態を持つ():
	var session := BattleSession.new(Vector2i(1, 0), Vector2i(0, 0), 1.5, 0.2)
	assert_eq(session.chunk_hex, Vector2i(1, 0))
	assert_eq(session.return_hex, Vector2i(0, 0))
	assert_eq(session.return_zoom, 1.5)
	assert_eq(session.return_min_zoom, 0.2)
