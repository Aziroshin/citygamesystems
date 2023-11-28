extends RefCounted
class_name NilableSkeleton3D

var is_nil: bool = true
var value: Skeleton3D:
	get:
		return value
	set(p_value):
		is_nil = false
		value = p_value

func set_value(p_value: Skeleton3D) -> NilableSkeleton3D:
	value = p_value
	return self
