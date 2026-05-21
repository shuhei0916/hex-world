class_name SpeedLabel
extends Label

## 生産速度を表示するコンポーネント。レシピがセットされている間は常に表示。

var _current_recipe: Recipe = null
var _output_multiplier: int = 1


func _ready():
	visible = false


func on_recipe_changed(recipe: Recipe):
	_current_recipe = recipe
	_update()


func set_multiplier(n: int):
	_output_multiplier = n
	_update()


func _update():
	if _current_recipe:
		if _current_recipe.craft_time > 0:
			text = "%.1f/m" % (60.0 / _current_recipe.craft_time * _output_multiplier)
			visible = true
		else:
			text = "Inf/m"
			visible = true
	else:
		visible = false
