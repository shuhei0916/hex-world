class_name Territory
extends RefCounted

## どの chunk を所有しているか。最初の chunk と、戦って解放した chunk を所有する。

signal changed

# planet があれば、その外の chunk は解放できない
var planet: Planet = null

# 所有している chunk の集合
var _owned: Dictionary[Vector2i, bool] = {}


func claim(chunk_hex: Vector2i) -> void:
	_owned[chunk_hex] = true
	changed.emit()


func is_owned(chunk_hex: Vector2i) -> bool:
	return _owned.has(chunk_hex)


func get_owned_hexes() -> Array[Vector2i]:
	var hexes: Array[Vector2i] = []
	hexes.assign(_owned.keys())
	return hexes


# 戦って解放できるか。まだ所有していなくて、所有している chunk の隣にあること
func can_challenge(chunk_hex: Vector2i) -> bool:
	if is_owned(chunk_hex) or (planet and not planet.has_chunk(chunk_hex)):
		return false
	for dir in range(6):
		if is_owned(Hex.neighbor(chunk_hex, dir)):
			return true
	return false
