extends Node2D

const TILE_SCENE = preload("res://HexTile.tscn")  # HexTileシーンをロード

func spawn_tile():
	var tile_shape = get_random_shape()
	var tile_node = TILE_SCENE.instance()
	add_child(tile_node)
	for cell in tile_shape:
		var hex_tile = TILE_SCENE.instance()
		hex_tile.position = cell_to_world(cell)
		tile_node.add_child(hex_tile)

func cell_to_world(cell):
	var size = 50  # 六角形の半径
	var x = size * 3/2 * cell.x
	var y = size * sqrt(3) * (cell.y + 0.5 * (cell.x % 2))
	return Vector2(x, y)
