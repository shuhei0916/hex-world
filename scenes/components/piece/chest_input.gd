class_name ChestInput
extends Node

## 搬入チェストの受け入れ口。届いたアイテムを共有倉庫（SharedStorage）へ入れる。
## 倉庫は設置時に Chunk から渡される。

var _storage: SharedStorage


func set_storage(storage: SharedStorage) -> void:
	_storage = storage


func get_storage() -> SharedStorage:
	return _storage


# 倉庫のそのアイテムが上限なら受け入れない（上流のコンベアが止まる）
func can_accept_item(item_name: String) -> bool:
	return _storage != null and _storage.can_add(item_name)


func add_item(item_name: String, amount: int) -> void:
	if _storage:
		_storage.add(item_name, amount)
