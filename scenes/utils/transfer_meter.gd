class_name TransferMeter
extends RefCounted

## 渡したアイテムを数え、直近 WINDOW 秒から品目ごとの 個/分 を出す。
## 橋が隣の chunk へ渡した量をワールドマップに出すのに使う（幅は Crafter の実績レートと同じ）。

const WINDOW := Crafter.RATE_WINDOW

var _clock := 0.0
var _records: Array = []  # [時刻, 品目] を古い順に


func tick(delta: float) -> void:
	_clock += delta
	while not _records.is_empty() and _records[0][0] < _clock - WINDOW:
		_records.pop_front()


func record(item_name: String) -> void:
	_records.append([_clock, item_name])


# 品目 → 個/分。計り始めてまだ WINDOW 秒たっていなければ、経った時間（最低1秒）で割る
func get_items_per_minute() -> Dictionary:
	var counts := {}
	for entry in _records:
		counts[entry[1]] = counts.get(entry[1], 0) + 1
	var span = WINDOW if _clock >= WINDOW else maxf(_clock, 1.0)
	var result := {}
	for item_name in counts:
		result[item_name] = counts[item_name] * 60.0 / span
	return result
