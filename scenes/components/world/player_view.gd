class_name PlayerView
extends Node2D
## プレイヤーキャラクターの表示。戦闘の主人公と同じ色の、陰影のない丸。

const RADIUS := 20.0
const OUTLINE_WIDTH := 3.0
const OUTLINE_COLOR := Color(0.1, 0.12, 0.16)
## 1歩ぶんすべるのにかかる秒数。歩く間隔より短くして、押し続けても動きが途切れて見えないようにする
const SLIDE_SECONDS := 0.1

var _tween: Tween


func _init() -> void:
	name = "PlayerView"
	# 施設やベルトの上のアイテムより手前に描く
	z_index = 10


## 歩いた先へすべるように動く
func slide_to(target: Vector2) -> void:
	_stop_tween()
	_tween = create_tween()
	_tween.tween_property(self, "position", target, SLIDE_SECONDS)


## すぐにその位置へ置く（chunk を並べ直したときなど）
func jump_to(target: Vector2) -> void:
	_stop_tween()
	position = target


func _stop_tween() -> void:
	if _tween and _tween.is_valid():
		_tween.kill()


func _draw() -> void:
	draw_circle(Vector2.ZERO, RADIUS + OUTLINE_WIDTH, OUTLINE_COLOR)
	draw_circle(Vector2.ZERO, RADIUS, UnitView.PLAYER_COLOR)
