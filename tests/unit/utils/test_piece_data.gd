# gdlint:disable=constant-name
extends GutTest


func test_PieceTypeエニュームが存在する():
	assert_true(PieceData.Type.CONVEYOR == 0)
	assert_true(PieceData.Type.SMELTER == 1)
	assert_true(PieceData.Type.CUTTER == 2)
	assert_true(PieceData.Type.MIXER == 3)
	assert_true(PieceData.Type.PAINTER == 4)
	assert_true(PieceData.Type.MINER == 5)
	assert_true(PieceData.Type.ASSEMBLER == 6)
	assert_true(PieceData.Type.CHEST == 7)


func test_PieceType_HUBが存在する():
	assert_true("HUB" in PieceData.Type.keys())


func test_PieceDataをインスタンス化できる():
	var data = PieceData.new()
	assert_not_null(data)


func test_PieceDataにはshapeフィールドが存在しない():
	var data = PieceData.new()
	assert_false("shape" in data, "shape は各ピースシーンに移行済み")


func test_PieceDataにはget_dataメソッドが存在しない():
	assert_false(PieceData.new().has_method("get_data"), "get_data は削除済み")


class TestPieceDataUnlock:
	extends GutTest

	func before_each():
		HubGoals.level = 1
		HubGoals.gained_rewards = {}

	func test_CONVEYORは常にアンロック済み():
		assert_true(PieceData.is_unlocked(PieceData.Type.CONVEYOR))

	func test_MINERは常にアンロック済み():
		assert_true(PieceData.is_unlocked(PieceData.Type.MINER))

	func test_SMELTERはunlock_smelter未取得のときロックされる():
		assert_false(PieceData.is_unlocked(PieceData.Type.SMELTER))

	func test_SMELTERはunlock_smelter取得済みのときアンロックされる():
		HubGoals.gained_rewards["unlock_smelter"] = true
		assert_true(PieceData.is_unlocked(PieceData.Type.SMELTER))

	func test_SENDERは常にアンロック済み():
		assert_true(PieceData.is_unlocked(PieceData.Type.SENDER))

	func test_RECEIVERは常にアンロック済み():
		assert_true(PieceData.is_unlocked(PieceData.Type.RECEIVER))
