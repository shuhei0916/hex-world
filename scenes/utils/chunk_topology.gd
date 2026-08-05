class_name ChunkTopology
extends RefCounted


# チャンク内部は pointy-top、world map は flat-top レイアウトで描画されており、
# 同じ方向インデックスでもピクセル角度が60度(インデックス1つ分)ズレるための補正。
static func to_world_direction(edge_dir: int) -> int:
	return (edge_dir + 1) % 6


# 隣接チャンクは回転せず同じローカル座標系で描かれているため、単純な原点対称(-h)では
# 辺は合っても辺内の位置が逆側の端になってしまう。原点対称のあと、辺を定義する座標
# (edge_dir % 3 で決まる軸)以外の2軸を入れ替えることで、辺内の対応位置を保つ。
static func mirror_hex(hex: Hex, edge_dir: int) -> Hex:
	var negated = Hex.scale(hex, -1)
	match edge_dir % 3:
		0:  # E/W の辺 → r, s を入れ替え
			return Hex.new(negated.q, negated.s, negated.r)
		1:  # NE/SW の辺 → q, s を入れ替え
			return Hex.new(negated.s, negated.r, negated.q)
		_:  # NW/SE の辺 → q, r を入れ替え
			return Hex.new(negated.r, negated.q, negated.s)
