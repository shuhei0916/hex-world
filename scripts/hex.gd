class_name Hex
extends RefCounted

var q: int
var r: int  
var s: int

func _init(q_val: int, r_val: int, s_val: int):
	q = q_val
	r = r_val
	s = s_val

func is_valid() -> bool:
	return (q + r + s) == 0

# 六角形算術演算（本家 redblob_hex.py に準拠）
static func add(a: Hex, b: Hex) -> Hex:
	return Hex.new(a.q + b.q, a.r + b.r, a.s + b.s)

static func subtract(a: Hex, b: Hex) -> Hex:
	return Hex.new(a.q - b.q, a.r - b.r, a.s - b.s)