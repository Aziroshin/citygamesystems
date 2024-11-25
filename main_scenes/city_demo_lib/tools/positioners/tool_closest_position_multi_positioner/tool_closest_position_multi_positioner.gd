extends ToolLibToolMultiPositioner
class_name ToolClosestPositionMultiPositioner


func get_position(
	p_reference_position: Vector3,
	p_status := PositionGettingStatus.new()
) -> Vector3:
	var got_any_position := false
	var new_position := p_reference_position
	
	if len(positioners) >= 1:
		var status := PositionGettingStatus.new()
		var prospective_position := positioners[0].get_position(p_reference_position, status)
		if status.got_position:
			new_position = prospective_position
			got_any_position = true
	
	if len(positioners) >= 2:
		var shortest_distance_squared_so_far := (new_position - p_reference_position)\
			# Squared is faster and we don't need the actual length.
			.length_squared()
		var closest_positioner_so_far := positioners[0]
		
		for i_prospective in range(1, len(positioners)):
			var prospective_positioner := positioners[i_prospective]
			
			var status := PositionGettingStatus.new()
			var prospective_position := prospective_positioner.get_position(
				p_reference_position,
				status
			)
			if status.got_position:
				if not got_any_position:
					new_position = prospective_position
					got_any_position = true
					closest_positioner_so_far = prospective_positioner
					
				var closest_position_so_far_distance_squared := (
					new_position - p_reference_position
				).length_squared()
				var prospective_position_distance_squared := (
					prospective_position - p_reference_position
				).length_squared()
				if prospective_position_distance_squared < closest_position_so_far_distance_squared:
					new_position = prospective_position
					got_any_position = true
					closest_positioner_so_far = prospective_positioner
					
	if got_any_position:
		p_status.got_position = true
		return new_position
	return p_reference_position
