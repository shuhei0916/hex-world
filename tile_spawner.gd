extends Node2D

const TILE_SCENE = preload("res://hex_tile.tscn")  # HexTileシーンをロード

# 複数のセルで構成されたタイル（形状）の定義
const TILE_SHAPES = {
	"single": [Vector2(0, 0)],                   # 単一セル
	"horizontal_2": [Vector2(0, 0), Vector2(1, 0)],    # 水平2セル
	"vertical_2": [Vector2(0, 0), Vector2(0, 1)],    # 垂直2セル
	"L_shape": [Vector2(0, 0), Vector2(1, 0), Vector2(0, 1)],  # L字型
	"bar": [Vector2(0, 0), Vector2(1, 0), Vector2(2, 0), Vector2(3, 0)],  # 水平4セル (Tetrahex - bar)
	"worm": [Vector2(0, 0), Vector2(0, 1), Vector2(0, 2), Vector2(0, 3)],  # 垂直4セル (Tetrahex - worm)
	"pistol": [Vector2(0, 0), Vector2(1, 0), Vector2(1, 1), Vector2(2, 1)],  # ジグザグ型 (Tetrahex - pistol)
	"propeller": [Vector2(0, 0), Vector2(1, 0), Vector2(1, 1), Vector2(2, 0)],  # T型 (Tetrahex - propeller)
	"arch": [Vector2(0, 0), Vector2(1, 0), Vector2(1, -1), Vector2(2, 0)],  # アーチ型 (Tetrahex - arch)
	"bee": [Vector2(0, 0), Vector2(1, 0), Vector2(0, 1), Vector2(-1, 1)],  # 蜂型 (Tetrahex - bee)
	"wave": [Vector2(0, 0), Vector2(1, 0), Vector2(2, -1), Vector2(3, -1)]  # 波型 (Tetrahex - wave)
}

func spawn_tile():
	var tile_shape = get_random_shape()
	var tile_node = TILE_SCENE.instantiate()
	add_child(tile_node)
	for cell in tile_shape:
		var hex_tile = TILE_SCENE.instantiate()
		hex_tile.position = cell_to_world(cell)
		tile_node.add_child(hex_tile)

func cell_to_world(cell):
	var size = 50  # 六角形の半径
	var x = size * 3/2 * cell.x
	var y = size * sqrt(3) * (cell.y + 0.5 * (int(cell.x) % 2)) # %演算子をそろえるときはint % intの型に揃えて！
	return Vector2(x, y)
	
func get_random_shape():
	var keys = TILE_SHAPES.keys()
	return TILE_SHAPES[keys[randi() % keys.size()]]
	
	
func _ready():
	randomize()  # ランダムシードを設定
	for i in range(3):  # 3つのタイルを生成
		spawn_tile()
