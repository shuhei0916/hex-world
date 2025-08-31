extends GutTest

# Player - 動作するドキュメント
# ゲーム内プレイヤーキャラクターとして、hex座標系でのナビゲーションを提供する
class_name TestPlayer

const PlayerScene = preload("res://scenes/Player.tscn")
var player: Player

func before_each():
	player = PlayerScene.instantiate()

func after_each():
	player.queue_free()

func test_Playerクラスが正しく初期化される():
	assert_not_null(player)
	assert_true(player is Node2D)

func test_Playerは初期位置でhex座標00に配置される():
	assert_eq(player.current_hex_position.q, 0)
	assert_eq(player.current_hex_position.r, 0)

func test_Playerはicon_svgスプライトを持つ():
	var sprite = player.get_node_or_null("Sprite2D")
	assert_not_null(sprite)
	assert_not_null(sprite.texture)