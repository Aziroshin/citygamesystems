extends ToolLibToolMultiPositioner
class_name ToolFirstPositionMultiPositioner


func get_position(
	p_reference_position: Vector3,
	p_status := PositionGettingStatus.new()
) -> Vector3:
	# We could initialize a var `position` with `p_reference_position` and
	# return it at the end, setting the variable directly in the loop.
	# However, this would put too much responsibility into the implementation
	# of `get_position` of the child positioners, since, if they return a 
	# default position, we would return that default position as well.
	#
	# Since positioners don't have to be implemented with the guarantees of some
	# particular multi positioner in mind, this could introduce surprising and
	# annoying to debug behaviour if some positioner returned some weird default
	# (something other than the passed reference position).
	for positioner in positioners:
		var new_position := positioner.get_position(p_reference_position, p_status)
		if p_status.got_position:
			return new_position
	return p_reference_position
