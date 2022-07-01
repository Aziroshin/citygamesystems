extends RefCounted
class_name NilableNode3D

var is_nil: bool = true
var value: Node3D:
	get:
		return value
	set(new_value):
		is_nil = false
		value = new_value

func set_value(new_value: Node3D) -> NilableNode3D:
	value = new_value
	return self
	
