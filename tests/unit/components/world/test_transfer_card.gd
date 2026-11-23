extends GutTest

## ワールドマップの輸送のカード

const NE := Vector2(0.866, -0.5)


func test_矢印は運ぶ向きに細長く_先端がその向きの一番先にある():
	var shape: PackedVector2Array = TransferCard.arrow_shape(Vector2.ZERO, NE, 16.0)
	var along = Array(shape).map(func(p): return p.dot(NE))
	var across = Array(shape).map(func(p): return p.dot(NE.orthogonal()))
	var length = along.max() - along.min()
	var width = across.max() - across.min()
	# ほぼ正三角形だと、どの角が先端か見分けられない
	assert_gt(length, width * 1.4, "向きに沿って細長い")
	assert_eq(along.find(along.max()), 0, "先頭の点が先端")
	assert_almost_eq(across[0], 0.0, 0.001, "先端は中心線の上")
