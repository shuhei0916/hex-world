extends GutTest

# Player - 動作するドキュメント
# ゲーム内プレイヤーキャラクターとして、hex座標系でのナビゲーションを提供する
class_name TestPlayer

const PlayerClass = preload("res://scripts/player.gd")

func test_Playerクラスが正しく初期化される():
	var player = PlayerClass.new()
	
	assert_not_null(player)
	assert_true(player is Node2D)
	player.queue_free()

func test_Playerは初期位置でhex座標00に配置される():
	var player = PlayerClass.new()
	
	assert_eq(player.current_hex_position.q, 0)
	assert_eq(player.current_hex_position.r, 0)
	player.queue_free()

func test_Playerはicon_svgスプライトを持つ():
	var player = PlayerClass.new()
	
	var sprite = player.get_node_or_null("Sprite2D")
	assert_not_null(sprite)
	assert_not_null(sprite.texture)
	
	player.queue_free()