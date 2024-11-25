extends ToolLibToolCollidingPositioner
class_name ToolCornerSnapPositioner


func _update_position() -> void:
	position_getting_status.got_position = false
	if is_colliding():
		for colliding_object in colliding_objects.get_all():
			if [
			CityGameGlobals.NodeGroups.CGS_CORNER_COLLIDERS,
			CityGameGlobals.NodeGroups.CGS_TOOL_COLLIDERS
			].all(func(group): return colliding_object.is_in_group(group)):
				position = colliding_object.transform.origin
				position_getting_status.got_position = true
				return
	position = collider.transform.origin
