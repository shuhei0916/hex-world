extends Polygon2D

# 複数のセルで構成されたタイル（形状）の定義
const TILE_SHAPES = [
	[Vector2(0, 0)],                   # 単一セル
	[Vector2(0, 0), Vector2(1, 0)],    # 水平2セル
	[Vector2(0, 0), Vector2(0, 1)],    # 垂直2セル
	[Vector2(0, 0), Vector2(1, 0), Vector2(0, 1)]  # L字型
]


func _ready():
	var radius = 50  # 六角形の半径
	var points = []
	var x_offset = 100
	var y_offset = 200
	
	for i in range(6):
		var angle = PI / 3 * i
		points.append(Vector2(cos(angle), sin(angle)) * radius + Vector2(x_offset, y_offset))
	polygon = points

func get_random_shape():
	return TILE_SHAPES[randi() % TILE_SHAPES.size()]
