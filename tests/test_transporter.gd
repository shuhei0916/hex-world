extends GutTest

var Transporter = load("res://scenes/components/piece/transporter.gd")
var ItemContainer = load("res://scenes/components/piece/item_container.gd")
var Piece = load("res://scenes/components/piece/piece.gd")

var transporter
var source_container
var target_piece

func before_each():
	if Transporter:
		transporter = Transporter.new()
	if ItemContainer:
		source_container = ItemContainer.new()
	if Piece:
		target_piece = Piece.new()
		var in_store = ItemContainer.new()
		target_piece.input_storage = in_store
		target_piece.add_child(in_store)

func after_each():
	if transporter: transporter.free()
	if source_container: source_container.free()
	if target_piece: target_piece.free()

func test_アイテムを搬出できる():
	if not transporter: return
	
	transporter.setup(source_container)
	source_container.add_item("test_item", 10)
	var targets = [target_piece]
	
	# 実行
	transporter.push(targets)
	
	# 検証
	assert_eq(source_container.get_item_count("test_item"), 9, "1つ減っているべき")
	assert_eq(target_piece.get_item_count("test_item"), 1, "1つ増えているべき")

func test_クールダウン中は搬出しない():
	if not transporter: return
	
	transporter.setup(source_container)
	source_container.add_item("test_item", 10)
	var targets = [target_piece]
	
	# 1回目: 成功 -> クールダウン発生
	transporter.push(targets)
	assert_eq(source_container.get_item_count("test_item"), 9)
	
	# 2回目: クールダウン中なので失敗するはず
	transporter.push(targets)
	assert_eq(source_container.get_item_count("test_item"), 9, "変わらないはず")
	
	# 時間経過
	transporter.tick(1.0)
	
	# 再実行: 成功
	transporter.push(targets)
	assert_eq(source_container.get_item_count("test_item"), 8, "減っているはず")