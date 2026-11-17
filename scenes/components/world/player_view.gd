class_name PlayerView
extends Node2D
## プレイヤーキャラクターの表示。戦闘の主人公と同じ色の、陰影のない丸。

const RADIUS := 20.0
const OUTLINE_WIDTH := 3.0
const OUTLINE_COLOR := Color(0.1, 0.12, 0.16)


func _init() -> void:
	name = "PlayerView"
	# 施設やベルトの上のアイテムより手前に描く
	z_index = 10


func _draw() -> void:
	draw_circle(Vector2.ZERO, RADIUS + OUTLINE_WIDTH, OUTLINE_COLOR)
	draw_circle(Vector2.ZERO, RADIUS, UnitView.PLAYER_COLOR)
