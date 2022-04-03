extends Reference
class_name GdTypes

class NilableSpatial:
	var value: Spatial setget set_value
	var is_nil: bool = true
	
	func set_value(new_value: Spatial) -> NilableSpatial:
		is_nil = false
		value = new_value
		return self
