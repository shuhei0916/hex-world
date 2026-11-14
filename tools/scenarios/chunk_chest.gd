extends RefCounted
## chunk チェストでコンベア無しにアイテムが渡るかを出力する。
##
## 配置（アクティブチャンク）:
##   搬入側: コンベア (-4,3) → 搬入チェスト (-3,3)。コンベアに鉄鉱石を流し続ける。
##   搬出側: 搬出チェスト (-2,0) → コンベア (-1,0) → ハブ (0,0)。離れていて、搬入側とはつながっていない。
## 搬出チェストは実際の操作と同じく、クリック → アイテム選択パネルで鉄鉱石を選ぶ。

const CONVEYOR = preload("res://scenes/components/piece/conveyor.tscn")
const CHEST_IN = preload("res://scenes/components/piece/chest_in.tscn")
const CHEST_OUT = preload("res://scenes/components/piece/chest_out.tscn")
const FEED_SECONDS := 6.0


func run(scene: Node) -> void:
	var chunk: Chunk = scene.world.get_active_chunk()
	chunk.place_piece(CONVEYOR, Hex.new(-4, 3))
	chunk.place_piece(CHEST_IN, Hex.new(-3, 3))
	chunk.place_piece(CHEST_OUT, Hex.new(-2, 0))
	chunk.place_piece(CONVEYOR, Hex.new(-1, 0))
	var feeder: Piece = chunk.get_piece_at_hex(Hex.new(-4, 3))
	var chest_out: Piece = chunk.get_piece_at_hex(Hex.new(-2, 0))
	print(
		(
			"接続: コンベア→搬入=%s / 搬出→コンベア=%s"
			% [
				chunk.get_piece_at_hex(Hex.new(-3, 3)) in feeder.get_connected_pieces(),
				chunk.get_piece_at_hex(Hex.new(-1, 0)) in chest_out.get_connected_pieces(),
			]
		)
	)

	await _feed(scene, feeder, FEED_SECONDS)
	print("[アイテム未選択で%d秒] 倉庫=%s %s" % [FEED_SECONDS, _storage(chunk), _delivered()])

	scene._hover_local(chunk.hex_to_pixel(Hex.new(-2, 0)))
	var click = InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	scene._handle_local_click(click)
	print("搬出チェストをクリック → 選択パネル visible=%s" % scene.hud.item_picker.visible)
	scene.hud.item_picker.get_button("iron_ore").pressed.emit()
	await scene.get_tree().process_frame
	print("  選択後: %s" % scene.hud.info_panel.description_label.text.replace("\n", " | "))

	await _feed(scene, feeder, FEED_SECONDS)
	print("[鉄鉱石を選んで%d秒] 倉庫=%s %s" % [FEED_SECONDS, _storage(chunk), _delivered()])
	scene._hover_local(chunk.hex_to_pixel(Hex.new(-3, 3)))
	print("  搬入チェストにホバー: %s" % scene.hud.info_panel.description_label.text.replace("\n", " | "))


# コンベアが空くたびに鉄鉱石を載せ続ける
func _feed(scene: Node, feeder: Piece, seconds: float) -> void:
	var elapsed := 0.0
	while elapsed < seconds:
		if feeder.can_accept_item("iron_ore"):
			feeder.add_item("iron_ore", 1)
		await scene.get_tree().process_frame
		elapsed += scene.get_process_delta_time()


# ハブに届いた数（ハブの在庫）とレベル。目標の納品数はレベルが上がると0に戻るので使わない
func _delivered() -> String:
	return "ハブに届いた鉄鉱石=%d Lv%d" % [HubGoals.get_stock("iron_ore"), HubGoals.level]


func _storage(chunk: Chunk) -> Dictionary:
	return chunk.storage.get_contents()
