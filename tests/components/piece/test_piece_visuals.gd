extends GutTest

var piece_scene = load("res://scenes/components/piece/piece.tscn")
var piece: Piece


func before_each():
	piece = piece_scene.instantiate()
	add_child_autofree(piece)


func test_detail_mode_toggles_visibility():
	# 初期状態では詳細情報は非表示であるべき
	piece.set_detail_mode(false)

	var input_icon = piece.get_node_or_null("InputIcon")
	var speed_label = piece.get_node_or_null("SpeedLabel")
	var count_label = piece.get_node_or_null("StatusIcon/CountLabel")  # Output count

	if input_icon:
		assert_false(input_icon.visible, "InputIcon should be hidden by default")
	if speed_label:
		assert_false(speed_label.visible, "SpeedLabel should be hidden by default")
	if count_label:
		assert_false(count_label.visible, "CountLabel should be hidden by default")

	# 詳細モードON
	piece.set_detail_mode(true)
	piece.add_item("iron_ore", 1)  # データを入れて表示させる
	piece.add_to_output("iron_ingot", 1)

	# _update_visuals が呼ばれるはず

	if input_icon:
		assert_true(input_icon.visible, "InputIcon should be visible in detail mode")
	if count_label:
		assert_true(count_label.visible, "CountLabel should be visible in detail mode")

	# 詳細モードOFF
	piece.set_detail_mode(false)

	if input_icon:
		assert_false(input_icon.visible, "InputIcon should be hidden when detail mode is off")
	if count_label:
		assert_false(count_label.visible, "CountLabel should be hidden when detail mode is off")


func test_speed_display_only_in_detail_mode():
	var recipe = Recipe.new("test", {"iron_ore": 1}, {"iron_ingot": 1}, 2.0)
	piece.set_recipe(recipe)

	var speed_label = piece.get_node_or_null("SpeedLabel")

	# OFFなら非表示
	piece.set_detail_mode(false)
	if speed_label:
		assert_false(speed_label.visible, "SpeedLabel hidden in normal mode")

	# ONなら表示
	piece.set_detail_mode(true)
	if speed_label:
		assert_true(speed_label.visible, "SpeedLabel visible in detail mode")
		assert_true(speed_label.text.contains("/m"), "Speed text correct")
