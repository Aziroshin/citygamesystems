extends RefCounted
class_name NilableSkeleton3D

var is_nil: bool = true
var value: Skeleton3D:
	get:
		return value
	set(new_value):
		is_nil = false
		value = new_value

func set_value(new_value: Skeleton3D) -> NilableSkeleton3D:
	value = new_value
	return self
