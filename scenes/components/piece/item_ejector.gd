class_name ItemEjector
extends RefCounted

## 接続先ピースへアイテムを1個ずつラウンドロビンで搬出するヘルパー。
## Output と ConveyorLogic が合成で利用する（shapez の ItemEjector 相当）。
## 受け入れ先の判定は can_accept_item / add_item のダックタイピングで行う。

var connected_pieces: Array = []
var _rr_index: int = 0


# 接続先を巡回し、最初に受け入れ可能なピースへ item_name を1個渡す。
# 渡せたら true を返し、次回開始位置を1つ進める。
func try_eject(item_name: String) -> bool:
	var n = connected_pieces.size()
	if n == 0:
		return false
	for i in range(n):
		var target = connected_pieces[(_rr_index + i) % n]
		if target.has_method("can_accept_item") and target.has_method("add_item"):
			if target.can_accept_item(item_name):
				target.add_item(item_name, 1)
				_rr_index = (_rr_index + 1) % n
				return true
	return false
