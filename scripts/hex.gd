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