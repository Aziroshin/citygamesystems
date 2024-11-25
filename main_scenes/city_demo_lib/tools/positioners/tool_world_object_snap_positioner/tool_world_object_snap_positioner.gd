extends ToolLibToolCollidingPositioner
class_name ToolWorldObjectSnapPositioner

# "Imports": PositionerLib
const MultiPositioner := PositionerLib.MultiPositioner


func _update_position() -> void:
	position_getting_status.got_position = false
	
	if is_colliding():
		var colliding_positioners := MultiPositioner.new()
		for colliding_object in colliding_objects.get_all():
			var colliding_world_object := WorldObject.get_from_collider_or_null(colliding_object)
			if not colliding_world_object == null:
				var err := colliding_positioners.add_positioner(colliding_world_object.create_positioner())
		if colliding_positioners.has_positioners():
			position = colliding_positioners.get_closest_point(reference_position)
			position = position
			position_getting_status.got_position = true
	else:
		position = collider.transform.origin
	
