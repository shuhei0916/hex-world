class_name Territory
extends RefCounted

## どの chunk を所有しているか。最初の chunk と、戦って解放した chunk を所有する。

signal changed

# planet があれば、その外の chunk は解放できない
var planet: Planet = null

var _owned: Dictionary = {}  # Hex.to_key → Hex


func claim(chunk_hex: Hex) -> void:
	_owned[Hex.to_key(chunk_hex)] = chunk_hex
	changed.emit()


func is_owned(chunk_hex: Hex) -> bool:
	return _owned.has(Hex.to_key(chunk_hex))


func get_owned_hexes() -> Array[Hex]:
	var hexes: Array[Hex] = []
	hexes.assign(_owned.values())
	return hexes


# 戦って解放できるか。まだ所有していなくて、所有している chunk の隣にあること
func can_challenge(chunk_hex: Hex) -> bool:
	if is_owned(chunk_hex) or (planet and not planet.has_chunk(chunk_hex)):
		return false
	for dir in range(6):
		if is_owned(Hex.neighbor(chunk_hex, dir)):
			return true
	return false
