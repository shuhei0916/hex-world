class_name ChestOutput
extends Node

## 搬出チェストの取り出し口。選んだアイテムを共有倉庫（SharedStorage）から1個ずつ取り出し、
## 兄弟の ItemEjector に渡して隣のピースへ流す。倉庫は設置時に Chunk から渡される。
## 手元（ItemEjector）に持つのは1個だけなので、搬出先が詰まれば取り出しも止まる。

# どの範囲で中身を共有するか（SharedStorage.SCOPE_*）。シーン側で設定する
@export var scope: String = SharedStorage.SCOPE_CHUNK

# 取り出すアイテム。空文字は未選択（何も取り出さない）
var selected_item: String = ""

var _storage: SharedStorage

@onready var _ejector: ItemEjector = get_parent().get_node_or_null("ItemEjector")


func set_storage(storage: SharedStorage) -> void:
	_storage = storage


func get_storage() -> SharedStorage:
	return _storage


# 取り出すアイテムを選び直す。手元に取り出してあった別のアイテムは倉庫へ戻す。
func select_item(item_name: String) -> void:
	if item_name == selected_item:
		return
	_return_held_item()
	selected_item = item_name


func tick(_delta: float) -> void:
	if selected_item == "" or _storage == null or _ejector == null:
		return
	if _ejector.is_empty() and _storage.take(selected_item, 1):
		_ejector.add_item(selected_item, 1)


# 撤去されるとき、手元に取り出してあったアイテムを倉庫へ戻す
func on_piece_removed() -> void:
	_return_held_item()


func _return_held_item() -> void:
	if _storage == null or _ejector == null or _ejector.is_empty():
		return
	var item = _ejector.get_held_item()
	var count = _ejector.get_total_item_count()
	_ejector.consume_item(item, count)
	_storage.add(item, count)
