class_name HexCoordinate
extends RefCounted

var q: int
var r: int
var s: int

func _init(q_val: int, r_val: int, s_val: int):
	q = q_val
	r = r_val
	s = s_val

func is_valid() -> bool:
	return q + r + s == 0

func add(other: HexCoordinate) -> HexCoordinate:
	return HexCoordinate.new(q + other.q, r + other.r, s + other.s)

func subtract(other: HexCoordinate) -> HexCoordinate:
	return HexCoordinate.new(q - other.q, r - other.r, s - other.s)

func scale(factor: int) -> HexCoordinate:
	return HexCoordinate.new(q * factor, r * factor, s * factor)