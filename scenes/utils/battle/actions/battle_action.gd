class_name BattleAction
extends RefCounted
## 戦闘中にユニットが行う1つの行動。移動・攻撃・スキルはこれを継承する。

var actor: Unit


## 必要な行動ポイント。
func cost(_battle: Battle) -> int:
	return 0


## いまの戦況で実行できるか（行動ポイントの過不足は Battle が見る）。
func can_perform(_battle: Battle) -> bool:
	return false


func apply(_battle: Battle) -> void:
	pass
