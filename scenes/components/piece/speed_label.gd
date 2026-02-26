class_name SpeedLabel
extends Label

## 生産速度を表示するコンポーネント。detail_mode 時のみ表示。

var _current_recipe: Recipe = null
var _is_detail_mode: bool = false


func on_recipe_changed(recipe: Recipe):
	_current_recipe = recipe
	_update()


func on_detail_mode_changed(enabled: bool):
	_is_detail_mode = enabled
	_update()


func _update():
	if not _is_detail_mode:
		visible = false
		return

	if _current_recipe:
		if _current_recipe.craft_time > 0:
			text = "%.1f/m" % (60.0 / _current_recipe.craft_time)
			visible = true
		else:
			text = "Inf/m"
			visible = true
	else:
		visible = false
