extends Polygon2D

func _ready():
	var radius = 50  # 六角形の半径
	var points = []
	var x_offset = 100
	var y_offset = 200
	
	for i in range(6):
		var angle = PI / 3 * i
		points.append(Vector2(cos(angle), sin(angle)) * radius + Vector2(x_offset, y_offset))
	polygon = points
