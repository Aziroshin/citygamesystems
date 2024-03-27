extends ToolLibToolCollidingPositioner
class_name LayoutToolSnapPositioner

#Dependencies:
# - CityBuilder.Layout


func _update_position() -> void:
	super()
	#print("layout_tool_snap_positioner.gd: _update")
	#for colliding_object in colliding_objects.get_all():
		#if colliding_object is IndexedAreaToolCollider:
			#print("layout_tool_snap_positioner.gd: Tool collider found")
			#position = colliding_object.transform.origin
		#elif colliding_object.owner is CityBuilder.Layout:
			#var layout := colliding_object.owner as CityBuilder.Layout
