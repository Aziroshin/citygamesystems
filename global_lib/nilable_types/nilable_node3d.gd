extends RefCounted
class_name NilableNode3D

var is_nil: bool = true
var value: Node3D:
	get:
		return value
	set(p_value):
		is_nil = false
		value = p_value

func set_value(p_value: Node3D) -> NilableNode3D:
	value = p_value
	return self
	
