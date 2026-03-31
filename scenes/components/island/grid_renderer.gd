@tool
class_name GridRenderer
extends Node2D

# GridRenderer - HexTile の視覚管理と O(1) タイル検索を提供する

var hex_tile_scene = preload("res://scenes/components/hex_tile/hex_tile.tscn")
var _hex_to_tile: Dictionary = {}
var _layout: Layout


func setup(layout: Layout):
	_layout = layout


func draw_grid(hexes: Array[Hex]):
	for child in get_children():
		child.queue_free()
	_hex_to_tile.clear()

	for hex in hexes:
		var tile = hex_tile_scene.instantiate()
		tile.position = Layout.hex_to_pixel(_layout, hex)
		add_child(tile)
		tile.setup_hex(hex)
		_hex_to_tile[_key(hex)] = tile


func find_hex_tile(hex: Hex) -> HexTile:
	return _hex_to_tile.get(_key(hex), null)


func _key(hex: Hex) -> String:
	return Hex.to_key(hex)
