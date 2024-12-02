extends RefCounted
class_name PositionerLib


class Positioner extends RefCounted:
	
	## Override virtual method.
	func get_closest_point(_p_reference_point: Vector3) -> Vector3:
		push_warning("Not implemented. Returning `%s`" % Vector3())
		return Vector3()
		
	# The implementation is open - e.g. `MultiPositioner` gets its tags from
	# the positioners it wraps and doesn't support having any tags of its own,
	# whereas `TaggablePositioner` does and has methods for adding and removing
	# tags.
	#
	# If a Positioner doesn't do anything with tags, it can just leave this
	# default definition in place, so it'll always return an empty array.
	# Strictly speaking, it should probably be a subclass that adds this
	# method, since it kinda communicates the wrong idea if a positioner that
	# doesn't do anything with tags has such a method. Then again, I don't want
	# to overdo it too much with the class hierarchies.
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


class NodeRelativeWrappedPositioner extends Positioner:
	var _node: Node3D
	var _positioner: Positioner
	
	func _init(p_node: Node3D, p_positioner: Positioner):
		_node = p_node
		_positioner = p_positioner
		
	func get_closest_point(p_reference_point: Vector3) -> Vector3:
		return _positioner.get_closest_point(
			p_reference_point - _node.transform.origin
		) + _node.transform.origin
		
	func get_tags() -> PackedStringArray:
		return _positioner.get_tags()


class CurvePositioner extends TaggablePositioner:
	## Override virtual method.
	func get_all_curves() -> Array[Curve3D]:
		push_warning("Not implemented. Returning `%s`" % [])
		return []


class PointsGetter:
	func get_points() -> PackedVector3Array:
		push_warning("Not implemented. Returning empty `PackedVector3Array`.")
		return PackedVector3Array()


## Gets points from an array reference passed at instantiation time.
##
## Whilst the reference is not supposed to change during the lifetime of the
## object, the array is shared with any other references that exist to it,
## which means the array's content may get altered by other parts of the code.
## If this behaviour is relied on for sharing array data, it's important that
## other parts of the code don't replace their reference when updating the
## array, or they'll refer to a different array from there on out.
##
## The array reference may only be set once (which happens in `_init`). If a
## subsequent attempt is made to set it, an error is pushed.
class StaticFromArrayReferencePointsGetter extends PointsGetter:
	var _points_ro_set := false
	var _points_ro: PackedVector3Array:
		set(p_value):
			if not _points_ro_set:
				_points_ro = p_value
				_points_ro_set = true
			else:
				push_error(
					"Attempted setting readonly value of var `_points_ro` of "
					+ "a `StaticFromArrayReferencePointsGetter` (or subclass) "
					+ "object."
				)
	
	func _init(p_points: PackedVector3Array):
		_points_ro = p_points
		
	## `PackedVector3Array` reference as passed to this object at instantiation
	## time.
	func get_points() -> PackedVector3Array:
		return _points_ro


class PointsGetterPositioner extends TaggablePositioner:
	var _points_getter: PointsGetter
	
	func _init(p_points_getter: PointsGetter):
		_points_getter = p_points_getter
	
	func get_closest_point(p_reference_point: Vector3) -> Vector3:
		return GeoFoo.get_closest_point(p_reference_point, _points_getter.get_points())
		
		
class LerpedPointsGetterPositioner extends PointsGetterPositioner:
	func get_closest_point(p_reference_point: Vector3) -> Vector3:
		var lerped_point := GeoFoo.get_closest_lerped_point(
			p_reference_point, _points_getter.get_points()
		)
		return lerped_point
		
		
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
			
		func is_empty() -> bool:
			return _positioners_by_tag.is_empty()
	
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
		
	func has_positioners() -> bool:
		return not positioners.is_empty()

