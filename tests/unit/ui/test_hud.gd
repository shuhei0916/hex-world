extends GutTest

const HUDScene = preload("res://scenes/ui/hud/hud.tscn")

var hud: HUD
var piece_placer: PiecePlacer


func before_each():
	hud = HUDScene.instantiate()
	piece_placer = PiecePlacer.new()
	add_child_autofree(hud)
	add_child_autofree(piece_placer)

	hud.setup(piece_placer)


func test_HUDは9つのパレットスロットを持つ():
	assert_eq(hud.get_slot_count(), 9)


func test_アクティブスロット変更でUIハイライトが更新される():
	assert_eq(hud.get_active_index(), -1)

	# HUDを直接操作
	hud.select_slot(3)

	# 状態が更新されているか確認
	assert_eq(hud.get_active_index(), 3)
	assert_not_null(piece_placer.selected_piece_data, "PiecePlacerにデータがセットされているべき")


func test_スロットにピースのアイコンが表示される():
	# ToolBarの子要素としてスロットが存在する
	var slot0 = hud.toolbar.get_child(0)
	assert_not_null(slot0)
	assert_gt(slot0.get_child_count(), 0, "Slot should contain icon nodes")


func test_スロットをクリックすると選択が更新される():
	# ボタンのクリックを擬似的に発生させる
	var btn2 = hud.slot_buttons[2]

	# 手動でトグル状態をセットしてシグナルを呼ぶ（実際のクリック動作の再現）
	btn2.button_pressed = true
	hud._on_slot_pressed(2)

	assert_eq(hud.get_active_index(), 2, "スロット2を選択したらインデックス2がアクティブになるべき")
	assert_not_null(piece_placer.selected_piece_data)
