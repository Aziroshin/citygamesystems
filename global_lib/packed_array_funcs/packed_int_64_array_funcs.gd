extends RefCounted
class_name PackedInt64ArrayFuncs


static func get_max(array: PackedInt64Array) -> int:
	var largest_integer := 0
	for integer in array:
		largest_integer = max(integer, largest_integer)
	return largest_integer
