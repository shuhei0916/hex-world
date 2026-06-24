class_name EjectorRouter
extends RefCounted

## 接続先ピースへアイテムを1個ずつラウンドロビンで搬出するルーティングヘルパー。
## ItemEjector / BalancerLogic が合成で利用する（接続＋出力方向スロットの巡回）。
## 各接続は「出力方向(0-5)」を伴うスロットとして保持する。これにより描画側は
## 「実際に排出される方向」を読めて、表示と実排出が食い違わない。
## 受け入れ先の判定は can_accept_item / add_item のダックタイピングで行う。

var connected_pieces: Array = []
var connected_directions: Array = []  # connected_pieces と並行。各接続の出力方向(0-5)
var _rr_index: int = 0


func set_connections(pieces: Array, directions: Array = []) -> void:
	connected_pieces = pieces
	connected_directions = directions


# ラウンドロビン開始位置から最初に受け入れ可能な接続のインデックスを返す（無ければ -1）。
func _next_acceptable_index(item_name: String) -> int:
	var n = connected_pieces.size()
	if n == 0:
		return -1
	for i in range(n):
		var idx = (_rr_index + i) % n
		var target = connected_pieces[idx]
		if target.has_method("can_accept_item") and target.has_method("add_item"):
			if target.can_accept_item(item_name):
				return idx
	return -1


# 今 item_name を排出するなら向かう出力方向(0-5)。排出先が無ければ -1。
func target_direction(item_name: String) -> int:
	var idx = _next_acceptable_index(item_name)
	if idx < 0 or idx >= connected_directions.size():
		return -1
	return connected_directions[idx]


# 最初に受け入れ可能な接続先へ item_name を1個渡す。渡せたら true。
func try_eject(item_name: String) -> bool:
	var idx = _next_acceptable_index(item_name)
	if idx < 0:
		return false
	connected_pieces[idx].add_item(item_name, 1)
	_rr_index = (idx + 1) % connected_pieces.size()
	return true


# 指定方向の接続先のみへ排出を試みる。その方向が塞がれていれば待機（他方向へは流さない）。
func try_eject_to_direction(item_name: String, direction: int) -> bool:
	for i in range(connected_pieces.size()):
		if connected_directions[i] == direction:
			var target = connected_pieces[i]
			if target.has_method("can_accept_item") and target.can_accept_item(item_name):
				target.add_item(item_name, 1)
				_rr_index = (i + 1) % connected_pieces.size()
				return true
			return false  # 接続先あり、だが満杯 → 待機
	return false  # 方向が接続されていない
