class_name SharedStorage
extends RefCounted

## チェストが共有する倉庫。同じ倉庫につながるチェスト同士は、離れていても中身を共有する。
## どの倉庫につながるかはチェストの共有範囲（scope）で決まる:
##   chunk  … chunk ごとに1つ（Chunk.storage）
##   planet … 惑星全体で1つ（World.planet_storage）
## 設置や研究に使う「ハブの在庫」（HubGoals.stock）とは別物。

# 1種類あたりの上限。作りすぎたら搬入側が止まるようにする
const CAPACITY_PER_ITEM := 100
const SCOPE_CHUNK := "chunk"
const SCOPE_PLANET := "planet"
# ホバー表示での倉庫の呼び名
const SCOPE_NAMES = {SCOPE_CHUNK: "chunk の倉庫", SCOPE_PLANET: "惑星の倉庫"}

var _contents: Dictionary = {}  # {item_id: 個数}


func get_count(item_id: String) -> int:
	return _contents.get(item_id, 0)


# 中身の一覧 {item_id: 個数}（0個のアイテムは含まない）
func get_contents() -> Dictionary:
	return _contents.duplicate()


func can_add(item_id: String) -> bool:
	return get_count(item_id) < CAPACITY_PER_ITEM


func add(item_id: String, amount: int) -> void:
	_contents[item_id] = get_count(item_id) + amount


# 取り出せたら true。足りなければ何も減らさず false。
func take(item_id: String, amount: int) -> bool:
	if get_count(item_id) < amount:
		return false
	_contents[item_id] = get_count(item_id) - amount
	if _contents[item_id] <= 0:
		_contents.erase(item_id)
	return true


# セーブデータから中身を戻す
func load_contents(contents: Dictionary) -> void:
	_contents = {}
	for item_id in contents:
		if int(contents[item_id]) > 0:
			_contents[item_id] = int(contents[item_id])
