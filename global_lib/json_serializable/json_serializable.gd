extends RefCounted
class_name JsonSerializable


func to_json() -> String:
	return JSON.stringify(to_dict())
	
func to_dict() -> Dictionary:
	push_error(
		"Unimplemented pseudo-virtual method `to_dict` called. Returning empty {}."
	)
	return {}
