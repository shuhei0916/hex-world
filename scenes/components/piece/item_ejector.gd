class_name ItemEjector
extends Node2D

## アイテムを保持し接続先ピースへ搬出するコンポーネント（shapez の ItemEjector 相当）。
## 出力アイテムは内部スロット(_item/_count)が直接保持し、EJECT_TIME かけて中心から
## 出力ポート端へ「スライド」(_progress 0→1)してから排出する（shapez のスロット進行）。
## 接続先への巡回搬出は EjectorRouter に委譲。描画は ItemEjectorVisual が
## get_held_item/get_progress_ratio/get_target_direction を読んで担う。

# スライド時間。ベルト/スプリッターの搬送間隔と揃える（上限が転送レートと一致＝悪化させない）。
const EJECT_TIME = TransferBuffer.TRANSFER_TIME

var capacity: int = 1

var _ejector := EjectorRouter.new()
var _item: String = ""
var _count: int = 0
var _progress: float = 0.0
var _is_pushing: bool = false


func tick(delta: float):
	if _item == "":
		return
	_progress = minf(_progress + delta / EJECT_TIME, 1.0)
	if _progress >= 1.0:
		_try_eject_one()


func set_connected_pieces(pieces: Array, directions: Array = []) -> void:
	_ejector.set_connections(pieces, directions)
	if _progress >= 1.0:
		_try_eject_one()


func get_connected_pieces() -> Array:
	return _ejector.connected_pieces


func add_item(item_name: String, amount: int):
	if _item == "":
		_item = item_name
		_count = amount
		_progress = 0.0
	elif _item == item_name:
		_count += amount


func consume_item(item_name: String, amount: int):
	if _item == item_name:
		_count -= amount
		if _count <= 0:
			_item = ""
			_count = 0
			_progress = 0.0


func get_item_count(item_name: String) -> int:
	return _count if _item == item_name else 0


func get_total_item_count() -> int:
	return _count


func set_capacity(n: int):
	capacity = n


func is_full() -> bool:
	return _count >= capacity


func is_empty() -> bool:
	return _count <= 0


# 描画用: 保持アイテム / スライド進捗(0..1) / 実際に向かう出力方向(0-5, 無ければ-1)。
func get_held_item() -> String:
	return _item


func get_progress_ratio() -> float:
	return _progress


func get_target_direction() -> int:
	return _ejector.target_direction(_item)


# スライド完了(progress=1)後、受け入れ可能な接続先へ1個排出する。
func _try_eject_one() -> void:
	if _is_pushing or _item == "" or _progress < 1.0:
		return
	if _ejector.connected_pieces.is_empty():
		return
	_is_pushing = true
	if _ejector.try_eject(_item):
		_count -= 1
		if _count <= 0:
			_item = ""
			_count = 0
		_progress = 0.0  # 次のアイテム(あれば)は再びスライド
	_is_pushing = false
