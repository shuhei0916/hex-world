# gdlint:disable=max-public-methods,duplicated-load
extends GutTest

const HUDScene = preload("res://scenes/ui/hud/hud.tscn")
const MINER_SCENE = preload("res://scenes/components/piece/miner_t2.tscn")
const SMELTER_SCENE = preload("res://scenes/components/piece/smelter_t2.tscn")

var hud: HUD


func before_each():
	HubGoals.gained_rewards.clear()
	hud = HUDScene.instantiate()
	add_child_autofree(hud)


func after_each():
	HubGoals.gained_rewards.clear()
	HubGoals.creative_mode = false


func test_スロット8はSenderである():
	assert_eq(_get_slot_piece_type(7), PieceData.Type.SENDER)


func test_スロット9はReceiverである():
	assert_eq(_get_slot_piece_type(8), PieceData.Type.RECEIVER)


func test_unlocks_changed受信で未アンロックのスロットが有効になる():
	var smelter_btn = hud.toolbar.get_child(2) as Button
	assert_true(smelter_btn.disabled, "前提: Smelterスロットは初期状態でロック")
	HubGoals.creative_mode = true
	HubGoals.unlocks_changed.emit()
	assert_false(smelter_btn.disabled)


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


func test_機械スロット選択で情報パネルにt1の生産速度が表示される():
	# スロット2はSmelter。初期状態はt1（craft_time_multiplier=2.0）なので15/分
	var btn = hud.toolbar.get_child(2) as Button
	btn.button_pressed = true
	hud.on_slot_pressed(2)
	assert_eq(hud.info_panel.rate_label.text, "スピード: 15/分")


func test_Tキーでt2に切り替えると情報パネルの速度が更新される():
	# スロット2はSmelter。cycle_variantでt2（30/分）に切り替わる
	HubGoals.gained_rewards["unlock_smelter"] = true
	hud._refresh_unlock_states()
	var btn = hud.toolbar.get_child(2) as Button
	btn.button_pressed = true
	hud.on_slot_pressed(2)
	hud.cycle_variant()  # t1→t2
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


func test_set_chunk_coordinateで左上ラベルにチャンク座標が表示される():
	hud.set_chunk_coordinate(Hex.new(1, 0))
	assert_eq(hud.get_node("ChunkCoordLabel").text, "Chunk: 1, 0")


class TestHoveredPiece:
	extends GutTest

	const HUDScene = preload("res://scenes/ui/hud/hud.tscn")
	const SMELTER = preload("res://scenes/components/piece/smelter_t1.tscn")

	var hud: HUD
	var chunk: Chunk
	var smelter: Piece

	func before_each():
		HubGoals.reset()
		HubGoals.creative_mode = true
		hud = HUDScene.instantiate()
		add_child_autofree(hud)
		chunk = Chunk.new()
		add_child_autofree(chunk)
		chunk.place_piece(SMELTER, Hex.new(0, 0))
		smelter = chunk.get_piece_at_hex(Hex.new(0, 0))

	func after_each():
		HubGoals.reset()

	func test_設置済みピースにホバーすると名前と状態が表示される():
		hud.show_hovered_piece(smelter)
		assert_true(hud.info_panel.visible)
		assert_eq(hud.info_panel.name_label.text, smelter.piece_name)
		assert_string_contains(hud.info_panel.description_label.text, "材料待ち")

	func test_ホバー中の機械は実績と最大速度が表示される():
		hud.show_hovered_piece(smelter)
		assert_eq(hud.info_panel.rate_label.text, "実績: 0/分（最大 15/分）")

	func test_ホバーが外れると情報パネルが消える():
		hud.show_hovered_piece(smelter)
		hud.show_hovered_piece(null)
		assert_false(hud.info_panel.visible)

	func test_ホバーしたままでも状態の変化が表示に反映される():
		hud.show_hovered_piece(smelter)
		smelter.add_item("iron_ore", 1)
		smelter.tick(0.5)
		hud._process(0.1)
		assert_string_contains(hud.info_panel.description_label.text, "稼働中")

	func test_設置するピースを選んでいる間は選んだピースの説明を優先する():
		hud.slot_buttons[1].button_pressed = true
		hud.on_slot_pressed(1)
		hud.show_hovered_piece(smelter)
		hud._process(0.1)
		assert_eq(hud.info_panel.name_label.text, "Miner")

	func test_ピースの選択を解除するとホバー中のピースの情報に戻る():
		hud.slot_buttons[1].button_pressed = true
		hud.on_slot_pressed(1)
		hud.show_hovered_piece(smelter)
		hud.deselect()
		assert_eq(hud.info_panel.name_label.text, smelter.piece_name)

	func test_ホバー中のピースが撤去されると情報パネルが消える():
		hud.show_hovered_piece(smelter)
		chunk.remove_piece_at(Hex.new(0, 0))
		await get_tree().process_frame
		hud._process(0.1)
		assert_false(hud.info_panel.visible)


class TestStockAndCost:
	extends GutTest

	const HUDScene = preload("res://scenes/ui/hud/hud.tscn")

	var hud: HUD

	func before_each():
		HubGoals.reset()
		HubGoals.gained_rewards = {"unlock_smelter": true}
		hud = HUDScene.instantiate()
		add_child_autofree(hud)

	func after_each():
		HubGoals.reset()

	func _select_slot(index: int) -> void:
		hud.slot_buttons[index].button_pressed = true
		hud.on_slot_pressed(index)

	func test_在庫が無いときはなしと表示する():
		assert_eq(hud.stock_label.text, "在庫: なし")

	func test_在庫が増えると表示に反映される():
		HubGoals.add_stock("iron_ore", 5)
		HubGoals.add_stock("coal", 2)
		assert_eq(hud.stock_label.text, "在庫\nIron Ore 5\nCoal 2")

	func test_使い切ったアイテムは在庫の表示から消える():
		HubGoals.add_stock("iron_ore", 5)
		HubGoals.pay({"iron_ore": 5})
		assert_eq(hud.stock_label.text, "在庫: なし")

	func test_有料のピースを選ぶとコストが表示される():
		HubGoals.add_stock("iron_ore", 5)
		_select_slot(2)
		assert_string_contains(hud.info_panel.description_label.text, "コスト: Iron Ore 5")
		assert_false(hud.info_panel.description_label.text.contains("在庫不足"))

	func test_在庫が足りないピースを選ぶと在庫不足と表示される():
		_select_slot(2)
		assert_string_contains(hud.info_panel.description_label.text, "コスト: Iron Ore 5（在庫不足）")

	func test_無料のピースを選ぶとコストなしと表示される():
		_select_slot(0)
		assert_string_contains(hud.info_panel.description_label.text, "コスト: なし")

	func test_選んだまま在庫が増えると在庫不足の表示が消える():
		_select_slot(2)
		HubGoals.add_stock("iron_ore", 5)
		assert_false(hud.info_panel.description_label.text.contains("在庫不足"))


class TestResearchEntry:
	extends GutTest

	const HUDScene = preload("res://scenes/ui/hud/hud.tscn")

	var hud: HUD

	func before_each():
		HubGoals.reset()
		hud = HUDScene.instantiate()
		add_child_autofree(hud)

	func after_each():
		HubGoals.reset()

	func test_研究パネルは最初は閉じている():
		assert_false(hud.research_panel.visible)

	func test_研究ボタンを押すと研究パネルが開く():
		hud.research_button.pressed.emit()
		assert_true(hud.research_panel.visible)

	func test_研究できるものが無いときボタンには件数を出さない():
		assert_eq(hud.research_button.text, "研究 [E]")

	func test_研究できるものがあるとボタンに件数が出る():
		HubGoals.level = 3
		HubGoals.add_stock("iron_ingot", 20)
		assert_eq(hud.research_button.text, "研究 [E] (2)")

	func test_研究すると件数が減る():
		HubGoals.level = 3
		HubGoals.add_stock("iron_ingot", 20)
		HubGoals.research("unlock_assembler")
		assert_eq(hud.research_button.text, "研究 [E]")


class TestChestSlots:
	extends GutTest

	const HUDScene = preload("res://scenes/ui/hud/hud.tscn")
	const CHEST_OUT = preload("res://scenes/components/piece/chest_out.tscn")

	var hud: HUD
	var chunk: Chunk
	var chest: Piece

	func before_each():
		HubGoals.reset()
		hud = HUDScene.instantiate()
		add_child_autofree(hud)
		chunk = Chunk.new()
		add_child_autofree(chunk)
		chunk.place_piece(CHEST_OUT, Hex.new(0, 0))
		chest = chunk.get_piece_at_hex(Hex.new(0, 0))

	func after_each():
		HubGoals.reset()

	func test_ツールバーに搬入チェストと搬出チェストのスロットがある():
		assert_eq(hud.slot_buttons.size(), 11)
		assert_eq(
			hud.get_scene_for_slot(9).resource_path, "res://scenes/components/piece/chest_in.tscn"
		)
		assert_eq(
			hud.get_scene_for_slot(10).resource_path, "res://scenes/components/piece/chest_out.tscn"
		)

	func test_チェストのスロットは研究するまで使えない():
		assert_true(hud.slot_buttons[9].disabled)
		assert_true(hud.slot_buttons[10].disabled)

	func test_チェストを研究するとスロットが使えるようになる():
		HubGoals.researched = {"unlock_chunk_chest": true}
		HubGoals.unlocks_changed.emit()
		assert_false(hud.slot_buttons[9].disabled)
		assert_false(hud.slot_buttons[10].disabled)

	func test_チェストのスロットを押すとそのピースが選ばれる():
		HubGoals.researched = {"unlock_chunk_chest": true}
		HubGoals.unlocks_changed.emit()
		watch_signals(hud)
		hud.slot_buttons[10].button_pressed = true
		hud.slot_buttons[10].pressed.emit()
		assert_signal_emitted_with_parameters(hud, "slot_selected", [hud.get_scene_for_slot(10)])

	func test_アイテム選択パネルは最初は閉じている():
		assert_false(hud.item_picker.visible)

	func test_搬出チェストに対してアイテム選択パネルを開ける():
		hud.open_item_picker(chest)
		assert_true(hud.item_picker.visible)

	func test_アイテムを選ぶと搬出チェストに設定されパネルが閉じる():
		hud.open_item_picker(chest)
		hud.item_picker.get_button("coal").pressed.emit()
		assert_eq(chest.get_node("ChestOutput").selected_item, "coal")
		assert_false(hud.item_picker.visible)

	func test_選択なしを選ぶと取り出しを止められる():
		chest.get_node("ChestOutput").select_item("coal")
		hud.open_item_picker(chest)
		hud.item_picker.get_button("").pressed.emit()
		assert_eq(chest.get_node("ChestOutput").selected_item, "")

	func test_アイテム選択パネルにはすべてのアイテムが並ぶ():
		for id in ItemDB.all_ids():
			assert_not_null(hud.item_picker.get_button(id), id)

	func test_搬出チェスト以外にはアイテム選択パネルを開かない():
		chunk.place_piece(preload("res://scenes/components/piece/conveyor.tscn"), Hex.new(2, 0))
		hud.open_item_picker(chunk.get_piece_at_hex(Hex.new(2, 0)))
		assert_false(hud.item_picker.visible)
