class_name ResearchTreeLayout
extends RefCounted

## 研究ツリーの配置（どの研究をどのマスに置くか）。画面の大きさとは無関係に、列と行の番号だけを決める。
## - 行: 系統（Research.BRANCHES の順に上から）。同じ系統で同じレベルの研究が複数あれば、
##   その系統の中で段を増やす。研究の無い系統の行は作らない
## - 列: 研究できるようになるハブのレベル。使われているレベルだけを小さい順に詰める
## defs は Research.DEFS と同じ形（branch / level を使う）。


## 研究 id → Vector2i(列, 行)
static func cells(defs: Dictionary) -> Dictionary:
	var columns := column_levels(defs)
	var rows := branch_rows(defs)
	var result := {}
	var used := {}  # Vector2i → true
	for id in defs:
		var def: Dictionary = defs[id]
		var column := columns.find(def["level"])
		for row in rows[def["branch"]]:
			var cell := Vector2i(column, row)
			if not used.has(cell):
				used[cell] = true
				result[id] = cell
				break
	return result


## 列ごとのハブのレベル（小さい順）
static func column_levels(defs: Dictionary) -> Array:
	var levels := []
	for def in defs.values():
		if not def["level"] in levels:
			levels.append(def["level"])
	levels.sort()
	return levels


## 系統 → その系統が使う行の番号（上から）。段の数は、同じレベルの研究がいちばん多い数
static func branch_rows(defs: Dictionary) -> Dictionary:
	var result := {}
	var next_row := 0
	for branch in Research.BRANCHES:
		var per_level := {}
		for def in defs.values():
			if def["branch"] == branch:
				per_level[def["level"]] = per_level.get(def["level"], 0) + 1
		if per_level.is_empty():
			continue
		var lanes: int = per_level.values().max()
		result[branch] = range(next_row, next_row + lanes)
		next_row += lanes
	return result
