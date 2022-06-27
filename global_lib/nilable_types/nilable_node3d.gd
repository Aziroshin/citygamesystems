extends RefCounted
class_name NilableNode3D

var is_nil: bool = true
var value: Node3D:
	get:
		return value
	set(new_value):
		set_value(new_value)

func set_value(new_value: Node3D) -> NilableNode3D:
	is_nil = false
	value = new_value
	return self
	
func get_value_or(do_this: Callable) -> Node3D:
	if not is_nil:
		return value
	return do_this.call()
