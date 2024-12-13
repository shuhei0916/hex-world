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
	
	#color = ALICE_BLUE
	color = Color(0, 1, 1, 1)
	
	# 外枠線の設定
	#outline_colors = [Color(0, 0, 0, 1)]
	#var outline_color = Color(0, 0, 0, 1)
	#var outline_width = 2
	#self.set_outline()
