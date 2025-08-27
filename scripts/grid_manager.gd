extends Node

# GridManager - グリッド管理システム
# Unity版のGridManager.csをGodotに移植

var grid_hexes: Dictionary = {}  # Set替わりにDictionaryを使用（key存在チェックが高速）
var occupied_hexes: Dictionary = {}

func _ready():
	print("GridManager initialized")

# グリッドのhexを登録
func register_grid_hex(hex: Hex):
	var key = _hex_to_key(hex)
	grid_hexes[key] = hex

# グリッド内かどうかを判定
func is_inside_grid(hex: Hex) -> bool:
	var key = _hex_to_key(hex)
	return grid_hexes.has(key)

# hexが占有されているかを判定
func is_occupied(hex: Hex) -> bool:
	var key = _hex_to_key(hex)
	return occupied_hexes.has(key)

# hexを占有する
func occupy(hex: Hex):
	var key = _hex_to_key(hex)
	occupied_hexes[key] = hex

# 複数のhexを占有する
func occupy_many(hexes: Array):
	for hex in hexes:
		occupy(hex)

# ピースが配置可能かを判定
func can_place(shape: Array, base_hex: Hex) -> bool:
	for offset in shape:
		var target = Hex.add(base_hex, offset)
		if not is_inside_grid(target):
			return false
		if is_occupied(target):
			return false
	return true

# ピースを配置する
func place_piece(shape: Array, base_hex: Hex):
	for offset in shape:
		var target = Hex.add(base_hex, offset)
		occupy(target)

# ピースを解除する
func unplace_piece(shape: Array, base_hex: Hex):
	for offset in shape:
		var target = Hex.add(base_hex, offset)
		var key = _hex_to_key(target)
		occupied_hexes.erase(key)

# グリッド状態をクリア（テスト用）
func clear_grid():
	grid_hexes.clear()
	occupied_hexes.clear()

# HexをDictionary keyに変換するヘルパー
func _hex_to_key(hex: Hex) -> String:
	return "%d,%d,%d" % [hex.q, hex.r, hex.s]