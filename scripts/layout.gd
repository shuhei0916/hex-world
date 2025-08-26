class_name Layout
extends RefCounted

var orientation: Orientation
var size: Vector2
var origin: Vector2

func _init(orientation_val: Orientation, size_val: Vector2, origin_val: Vector2):
	orientation = orientation_val
	size = size_val
	origin = origin_val