extends Node2D

const TILE_SCENE = preload("res://hex_tile.tscn")  # HexTileシーンをロード

# 複数のセルで構成されたタイル（形状）の定義
const TILE_SHAPES = {
	"bar": [Vector2(0, 0), Vector2(0, 1), Vector2(0, 2), Vector2(0, 3)],
	"worm": [Vector2(0, 0), Vector2(0, 1), Vector2(0, 2), Vector2(1, 2)],
	"pistol": [Vector2(0, 0), Vector2(1, 0), Vector2(1, 1), Vector2(2, 1)],
	"propeller": [Vector2(0, 0), Vector2(1, 0), Vector2(1, 1), Vector2(2, 0)],
	"arch": [Vector2(0, 0), Vector2(1, 0), Vector2(1, 1), Vector2(0, 2)],
	"bee": [Vector2(0, 0), Vector2(1, 0), Vector2(1, -1), Vector2(2, 0)],
	"wave": [Vector2(0, 0), Vector2(1, 0), Vector2(2, 0), Vector2(3, 0)],
}

func spawn_tile():
	#var tile_shape = get_random_shape()
	var tile_shape = TILE_SHAPES["arch"]
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
	
#func get_tile_shape(tile_name):
	
func get_random_shape():
	var keys = TILE_SHAPES.keys()
	print(keys)
	var res = TILE_SHAPES[keys[randi() % keys.size()]]
	print(res)
	return res
	
	
func _ready():
	randomize()  # ランダムシードを設定
	spawn_tile()
