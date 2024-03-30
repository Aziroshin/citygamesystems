extends ToolLibToolCollidingPositioner
class_name ToolCornerSnapPositioner


func _update_position() -> void:
	if is_colliding():
		for colliding_object in colliding_objects.get_all():
			if [CityGameGlobals.NodeGroups.CGS_CORNER_COLLIDERS,
				CityGameGlobals.NodeGroups.CGS_TOOL_COLLIDERS
			].all(func(group): colliding_object.is_in_group(group)):
				position = colliding_object.transform.origin
	else:
		position = collider.transform.origin
