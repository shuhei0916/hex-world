class_name EnemyPlan
extends RefCounted
## 敵1体が次の手番で行うことの予定。

## いまのマスから移動先までの経路。動かないならいまのマスだけ。
var path: Array[Vector2i] = []
## 移動のあと主人公を攻撃するか。
var attacks := false
