extends TileMap

# 複数のタイルで構成されたPolyhexの定義
const POLYHEX = {
	"bar": [Vector2(0, 0), Vector2(0, 1), Vector2(0, 2), Vector2(0, 3)],
	"worm": [Vector2(0, 0), Vector2(0, 1), Vector2(0, 2), Vector2(1, 2)],
	"pistol": [Vector2(0, 0), Vector2(1, 0), Vector2(1, 1), Vector2(2, 1)],
	"propeller": [Vector2(0, 0), Vector2(1, 0), Vector2(1, 1), Vector2(2, 0)],
	"arch": [Vector2(0, 0), Vector2(1, 0), Vector2(1, 1), Vector2(0, 2)],
	"bee": [Vector2(0, 0), Vector2(1, 0), Vector2(1, -1), Vector2(2, 0)],
	"wave": [Vector2(0, 0), Vector2(1, 0), Vector2(2, 0), Vector2(3, 0)],
}


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	spawn_polyhex("pistol")


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func spawn_polyhex(selected_polyhex):
	# TileMap上で現在使用中のタイルの最大X座標を探す
	var max_x = -INF
	for cell in get_used_cells(0):
		max_x = max(max_x, cell.x)
		#print(max_x)
	
	# Polyhexの基準位置（右横の開始位置）を設定
	var base_position = Vector2(max_x + 1, 0)

	# 選択されたPolyhexを取得
	var tile_shape = POLYHEX[selected_polyhex]

	# 各タイルをTileMapに配置
	for cell in tile_shape:
		var spawn_position = base_position + cell
		print("Spawning at:", spawn_position)
		set_cell(0, spawn_position, 0, Vector2i(0, 0), 1)
		#set_cell()
		#print("hehe")
