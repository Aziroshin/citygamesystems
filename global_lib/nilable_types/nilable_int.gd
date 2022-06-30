extends RefCounted
class_name NilableInt

var is_nil: bool = true
var value: int:
	get:
		return value
	set(new_value):
		is_nil = false
		value = new_value

func set_value(new_value: int) -> NilableInt:
	value = new_value
	return self
	
