extends RefCounted
class_name NilableTransform3D

var is_nil: bool = true
var value: Transform3D:
	get:
		return value
	set(p_value):
		is_nil = false
		value = p_value

func set_value(p_value: Transform3D) -> NilableTransform3D:
	value = p_value
	return self
