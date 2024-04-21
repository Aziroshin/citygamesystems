extends RefCounted
class_name PositionerLib


class Positioner extends RefCounted:
	
	## Override virtual method.
	func get_closest_point(_p_reference_point: Vector3) -> Vector3:
		push_warning("Not implemented. Returning `%s`" % Vector3())
		return Vector3()
		
	func get_tags() -> PackedStringArray:
		return []


class TaggablePositioner extends Positioner:
	var _tags := PackedStringArray()
	
	func get_tags() -> PackedStringArray:
		return _tags
		
	func add_tags(p_tags : PackedStringArray) -> void:
		for tag in p_tags:
			if not tag in _tags:
				_tags.append(tag)
	
	func remove_tags(p_tags: PackedStringArray) -> void:
		for i_tag in len(_tags):
			if _tags[i_tag] in p_tags:
				_tags.remove_at(i_tag)


class OriginPositioner extends TaggablePositioner:
	var node: Node3D
	
	func _init(p_node: Node3D):
		node = p_node
	
	func get_closest_point(_p_reference_point: Vector3) -> Vector3:
		return node.transform.origin


class CurvePositioner extends TaggablePositioner:
	## Override virtual method.
	func get_all_curves() -> Array[Curve3D]:
		push_warning("Not implemented. Returning `%s`" % [])
		return []


class MultiPositioner extends Positioner:
	class Positioners:
		var _positioners_by_tag := Dictionary()
		
		func get_by_tag(p_tag: String) -> Array[Positioner]:
			if p_tag in _positioners_by_tag:
				return _positioners_by_tag[p_tag]
			return []
			
		func add(p_tag: String, p_positioner: Positioner) -> Error:
			if not p_tag in _positioners_by_tag:
				_positioners_by_tag[p_tag] = []
			if p_positioner in _positioners_by_tag[p_tag]:
				return ERR_ALREADY_EXISTS
			
			_positioners_by_tag[p_tag].append(p_positioner)
			return OK
			
		func remove(p_tag: String, p_positioner: Positioner) -> Error:
			if p_tag in _positioners_by_tag:
				var positioners: Array[Positioner] = _positioners_by_tag[p_tag]
				var positioner_idx := positioners.find(p_positioner)
				
				if positioner_idx == -1:
					return ERR_DOES_NOT_EXIST
				if len(positioners) == 1:
					_positioners_by_tag.erase(p_tag)
					return OK
					
				positioners.remove_at(positioner_idx)
			return OK
				
		func get_tags() -> PackedStringArray:
			return _positioners_by_tag.keys()
	
	
	var enabled_positioners: Array[Positioner] = []
	var positioners := Positioners.new()
	
	func get_tags() -> PackedStringArray:
		return positioners.get_tags()
	
	func add_positioner(p_positioner: Positioner, p_enable := true) -> Error:
		for tag in p_positioner.get_tags():
			var err := positioners.add(tag, p_positioner)
			if not err == OK:
				return err
		if p_enable:
			enabled_positioners.append(p_positioner)
		return OK
		
	func enable_positioners_by_tag(p_tag: String) -> void:
		for positioner in positioners.get_by_tag(p_tag):
			enabled_positioners.append(positioner)
	
	func disable_positioners_by_tag(p_tag: String) -> void:
		var i_positioner := 0
		for positioner in enabled_positioners:
			if p_tag in positioner.get_tags():
				enabled_positioners.remove_at(i_positioner)
			i_positioner += 1
	
	func get_closest_point(p_reference_point: Vector3) -> Vector3:
		var closest_points := PackedVector3Array()
		for positioner in enabled_positioners:
			closest_points.append(positioner.get_closest_point(p_reference_point))
		return GeoFoo.get_closest_point(p_reference_point, closest_points)
