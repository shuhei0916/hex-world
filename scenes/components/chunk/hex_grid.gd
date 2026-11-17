class_name HexGrid
extends RefCounted

# HexGrid - 論理グリッド状態のみを管理する
# 登録済みのマスと占有済みのマスを集合（値が true の辞書）で持ち、クエリと変更を提供する

var _registered_hexes: Dictionary[Vector2i, bool] = {}
var _occupied_hexes: Dictionary[Vector2i, bool] = {}


func register_grid_hex(hex: Vector2i):
	_registered_hexes[hex] = true


func is_inside_grid(hex: Vector2i) -> bool:
	return _registered_hexes.has(hex)


func is_occupied(hex: Vector2i) -> bool:
	return _occupied_hexes.has(hex)


func occupy(hex: Vector2i):
	_occupied_hexes[hex] = true


func unoccupy(hex: Vector2i):
	_occupied_hexes.erase(hex)


func occupy_many(hexes: Array[Vector2i]):
	for hex in hexes:
		occupy(hex)


func can_place(shape: Array, base_hex: Vector2i) -> bool:
	for offset in shape:
		var target = base_hex + offset
		if not is_inside_grid(target):
			return false
		if is_occupied(target):
			return false
	return true


func clear_grid():
	_registered_hexes.clear()
	_occupied_hexes.clear()
