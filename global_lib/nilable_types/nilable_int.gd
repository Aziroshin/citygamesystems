extends RefCounted
class_name NilableInt

var is_nil: bool = true
var value: int:
	get:
		return value
	set(p_value):
		is_nil = false
		value = p_value

func set_value(p_value: int) -> NilableInt:
	value = p_value
	return self
	
