extends GutTest

## 研究ツリーの配置。行は系統、列は研究できるようになるハブのレベル（小さい順に詰める）。


func _def(branch: String, level: int, requires: Array = []) -> Dictionary:
	return {"branch": branch, "level": level, "requires": requires}


func test_同じ系統の研究は同じ行に並ぶ():
	var cells = ResearchTreeLayout.cells(
		{"a": _def("logistics", 2), "b": _def("logistics", 5), "c": _def("mining", 3)}
	)
	assert_eq(cells["a"].y, cells["b"].y)
	assert_ne(cells["a"].y, cells["c"].y)


func test_行は系統の順に上から並ぶ():
	var cells = ResearchTreeLayout.cells({"m": _def("mining", 2), "l": _def("logistics", 2)})
	assert_lt(cells["l"].y, cells["m"].y, "物流が採掘より上")


func test_列はハブのレベルの順で_使われていないレベルは詰める():
	var defs = {"a": _def("logistics", 2), "b": _def("mining", 5), "c": _def("chest", 9)}
	var cells = ResearchTreeLayout.cells(defs)
	assert_eq([cells["a"].x, cells["b"].x, cells["c"].x], [0, 1, 2])
	assert_eq(ResearchTreeLayout.column_levels(defs), [2, 5, 9])


func test_同じレベルの研究は系統が違っても同じ列():
	var cells = ResearchTreeLayout.cells({"a": _def("logistics", 4), "b": _def("combat", 4)})
	assert_eq(cells["a"].x, cells["b"].x)


func test_同じ系統で同じレベルの研究は_その系統の中で段を分ける():
	var defs = {"a": _def("logistics", 4), "b": _def("logistics", 4), "c": _def("mining", 4)}
	var cells = ResearchTreeLayout.cells(defs)
	assert_eq(cells["a"].x, cells["b"].x)
	assert_eq(absi(cells["a"].y - cells["b"].y), 1, "物流の中で2段になる")
	assert_gt(cells["c"].y, maxi(cells["a"].y, cells["b"].y), "採掘はその下")
	assert_eq(ResearchTreeLayout.branch_rows(defs)["logistics"], [0, 1])
	assert_eq(ResearchTreeLayout.branch_rows(defs)["mining"], [2])


func test_研究の無い系統の行は作らない():
	var defs = {"a": _def("logistics", 2), "c": _def("chest", 3)}
	assert_eq(ResearchTreeLayout.cells(defs)["c"].y, 1)
	assert_false(ResearchTreeLayout.branch_rows(defs).has("mining"))


func test_実際の研究では前提の研究が必ず左にある():
	var cells = ResearchTreeLayout.cells(Research.DEFS)
	for id in Research.all_ids():
		for required in Research.get_def(id)["requires"]:
			assert_lt(cells[required].x, cells[id].x, "%s の前提 %s" % [id, required])
