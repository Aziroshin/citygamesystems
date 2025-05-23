extends RayCast3D
class_name ToolMapRayCaster

## Offset around the point of origin of the raycast. Will cast from the offset
## point in the direction of the negative of the offset point (casting through
## the point of origin).
@export var cast_offset := Vector3(0.0, 100.0, 0.0)
signal result_map_points(p_result: Result)
var requests: Array[Request] = []


class Request:
	var id: int
	var source_points: PackedVector3Array
	
	func _init(
		p_id: int,
		p_source_points: PackedVector3Array
	):
		id = p_id
		source_points = p_source_points


class Result:
	var id: int
	var map_points: PackedVector3Array

	func _init(
		p_id: int,
		p_map_points: PackedVector3Array
	):
		id = p_id
		map_points = p_map_points


func cast(
	source_point: Vector3,
	source_point_offset: Vector3,
	target_point_offset: Vector3,
	space_state: PhysicsDirectSpaceState3D
) -> Dictionary:
	var query := PhysicsRayQueryParameters3D.create(
		source_point + source_point_offset,
		source_point + target_point_offset
	)
	return space_state.intersect_ray(query)


func _physics_process(_p_delta: float) -> void:
	if len(requests) > 0:
		var map_points := PackedVector3Array()
		var space_state := get_world_3d().direct_space_state
		var request: Request = requests.pop_back()
		
		var i_point := 0
		var i_added_points := 0
		for point in request.source_points:
			var cast_result := cast(point, cast_offset, -cast_offset, space_state)
			if cast_result.has("position"):
				map_points.append(cast_result["position"])
				i_added_points += 1
			else:
				push_error(
					"Street tool ray cast failed to collide with map at "
					+ "point idx %s." % i_point
				)
			i_point += 1
		
		var result := Result.new(
				request.id,
				map_points
			)
		result_map_points.emit(
			result
		)


func _on_request_map_points(p_request) -> void:
	requests.append(p_request)
