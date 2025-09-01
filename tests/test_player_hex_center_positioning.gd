extends GutTest

# Player hex中央配置機能 - 動作するドキュメント
# プレイヤーがhexグリッドの中央に正確に位置する機能のテスト
class_name TestPlayerHexCenterPositioning

const Player = preload("res://scripts/player.gd")

var player: Player
var grid_layout: Layout

func before_each():
	# グリッドレイアウトを作成（GridDisplayと同じ設定）
	var orientation = Layout.layout_pointy
	var size = Vector2(36.37306, 36.37306)  # GridDisplayと同じサイズ
	var origin = Vector2(0, 0)
	grid_layout = Layout.new(orientation, size, origin)
	
	# Playerインスタンスを作成
	player = Player.new()
	add_child(player)

func after_each():
	if player:
		player.queue_free()
		remove_child(player)
	player = null
	grid_layout = null

func test_Playerは初期化時にhex座標00の中央に配置される():
	# setup_grid_layoutを呼び出す
	player.setup_grid_layout(grid_layout)
	
	# hex(0,0)の中央座標を計算
	var expected_center = Layout.hex_to_pixel(grid_layout, Hex.new(0, 0))
	
	# プレイヤーの位置が期待される中央位置と一致することを確認
	assert_eq(player.global_position, expected_center, "プレイヤーがhex(0,0)の中央に配置されていない")
	
	# 現在のhex座標が(0,0)であることを確認
	assert_true(Hex.equals(player.current_hex_position, Hex.new(0, 0)), "プレイヤーの現在hex座標が(0,0)でない")

func test_setup_grid_layoutでグリッドレイアウトが設定される():
	# 初期状態ではgrid_layoutがnullであることを確認
	assert_null(player.grid_layout, "初期状態でgrid_layoutがnullでない")
	
	# setup_grid_layoutを呼び出す
	player.setup_grid_layout(grid_layout)
	
	# grid_layoutが正しく設定されることを確認
	assert_not_null(player.grid_layout, "setup_grid_layout後にgrid_layoutがnull")
	assert_eq(player.grid_layout, grid_layout, "設定されたgrid_layoutが期待値と異なる")