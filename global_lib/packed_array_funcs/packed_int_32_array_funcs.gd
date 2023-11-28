extends RefCounted
class_name PackedInt32ArrayFuncs


static func get_max(p_array: PackedInt32Array) -> int:
	var largest_integer := 0
	for integer in p_array:
		largest_integer = max(integer, largest_integer)
	return largest_integer
