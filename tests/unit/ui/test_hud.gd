extends GutTest

const HUDScene = preload("res://scenes/ui/hud/hud.tscn")
const MINER_SCENE = preload("res://scenes/components/piece/miner.tscn")
const SMELTER_SCENE = preload("res://scenes/components/piece/smelter_t2.tscn")

var hud: HUD


func before_each():
	HubGoals.gained_rewards.clear()
	hud = HUDScene.instantiate()
	add_child_autofree(hud)


func after_each():
	HubGoals.gained_rewards.clear()


func test_アクティブスロット変更でUIハイライトが更新される():
	assert_eq(hud.get_active_index(), -1)

	# HUDを直接操作（ボタンを真にしてハンドラを呼ぶ）
	var btn3 = hud.toolbar.get_child(3) as Button
	btn3.button_pressed = true
	hud.on_slot_pressed(3)

	# 状態が更新されているか確認
	assert_eq(hud.get_active_index(), 3)


func _get_slot_piece_type(index: int) -> PieceData.Type:
	var scene = hud.get_scene_for_slot(index)
	var piece = scene.instantiate()
	var piece_type = piece.piece_type
	piece.free()
	return piece_type


func test_スロット1はコンベアである():
	assert_eq(_get_slot_piece_type(0), PieceData.Type.CONVEYOR)


func test_スロット2はマイナーである():
	assert_eq(_get_slot_piece_type(1), PieceData.Type.MINER)


func test_スロット3はスメルターである():
	assert_eq(_get_slot_piece_type(2), PieceData.Type.SMELTER)


func test_スロット4はアッセンブラーである():
	assert_eq(_get_slot_piece_type(3), PieceData.Type.ASSEMBLER)


func test_スロットにアイコンテクスチャが設定されている():
	var slot0 = hud.toolbar.get_child(0) as Button
	assert_not_null(slot0.icon)


func test_スロットをクリックすると選択が更新される():
	# ボタンのクリックを擬似的に発生させる
	var btn2 = hud.toolbar.get_child(2) as Button

	# 手動でトグル状態をセットしてハンドラを呼ぶ
	btn2.button_pressed = true
	hud.on_slot_pressed(2)

	assert_eq(hud.get_active_index(), 2, "スロット2を選択したらインデックス2がアクティブになるべき")


func test_スロット選択時にslot_selectedがPackedSceneを持って発火される():
	watch_signals(hud)
	var btn = hud.toolbar.get_child(3) as Button
	btn.button_pressed = true
	hud.on_slot_pressed(3)
	var expected_scene = hud.get_scene_for_slot(3)
	assert_signal_emitted_with_parameters(hud, "slot_selected", [expected_scene])


func test_選択解除時にslot_selectedがnullを持って発火される():
	watch_signals(hud)
	hud.on_slot_pressed(-1)
	assert_signal_emitted_with_parameters(hud, "slot_selected", [null])


func test_deselect呼び出しでslot_selectedがnullを持って発火される():
	watch_signals(hud)
	hud.deselect()
	assert_signal_emitted_with_parameters(hud, "slot_selected", [null])


func test_スロット選択で情報パネルにピース名が表示される():
	var btn = hud.toolbar.get_child(1) as Button
	btn.button_pressed = true
	hud.on_slot_pressed(1)
	assert_eq(hud.info_panel.name_label.text, "Miner")


func test_選択解除で情報パネルが非表示になる():
	hud.info_panel.visible = true
	hud.deselect()
	assert_false(hud.info_panel.visible)


func test_機械スロット選択で情報パネルに生産速度が表示される():
	var btn = hud.toolbar.get_child(2) as Button
	btn.button_pressed = true
	hud.on_slot_pressed(2)
	assert_eq(hud.info_panel.rate_label.text, "スピード: 30/分")


func test_コンベアスロット選択で情報パネルに搬送速度が表示される():
	var btn = hud.toolbar.get_child(0) as Button
	btn.button_pressed = true
	hud.on_slot_pressed(0)
	assert_eq(hud.info_panel.rate_label.text, "スピード: 120/分")


func test_速度を持たないピース選択で情報パネルのRateLabelが非表示():
	# Painter（レシピ未定義＝生産速度なし）は速度行を出さない
	# HubGoals経由でアンロックしてから選択する
	HubGoals.gained_rewards["unlock_mixer"] = true
	hud._refresh_unlock_states()
	var btn = hud.toolbar.get_child(6) as Button
	btn.button_pressed = true
	hud.on_slot_pressed(6)
	assert_false(hud.info_panel.rate_label.visible)


func test_スロットはバリアントリストを持ちget_scene_for_slotはインデックス0のシーンを返す():
	# スロット0（コンベア）はバリアントが1つ。インデックス0のシーンが返る
	var scene = hud.get_scene_for_slot(0)
	var piece = scene.instantiate()
	assert_eq(piece.piece_type, PieceData.Type.CONVEYOR)
	piece.free()
