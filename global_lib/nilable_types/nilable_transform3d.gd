extends RefCounted
class_name NilableTransform3D

var is_nil: bool = true
var value: Transform3D:
	get:
		return value
	set(new_value):
		set_value(new_value)

func set_value(new_value: Transform3D) -> NilableTransform3D:
	is_nil = false
	value = new_value
	return self
