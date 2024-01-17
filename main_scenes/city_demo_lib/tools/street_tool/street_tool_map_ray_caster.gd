extends RayCast3D
class_name StreetToolMapRayCaster

enum State {
	IDLE,
	PROCESSING_REQUEST
}
## Offset around the point of origin of the raycast. Will cast from the offset
## point in the direction of the negative of the offset point (casting through
## the point of origin).
@export var cast_offset := Vector3(0.0, 100.0, 0.0)
var state: State = State.IDLE
signal result_map_points(p_points: PackedVector3Array)
var source_points := PackedVector3Array()


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
	if state == State.PROCESSING_REQUEST:
		var map_points := PackedVector3Array()
		var space_state := get_world_3d().direct_space_state
		
		for point in source_points:
			var result := cast(point, cast_offset, -cast_offset, space_state)
			if result.has("position"):
				map_points.append(result["position"])
			else:
				push_error("Street tool ray cast failed to collide with map.")
		
		result_map_points.emit(map_points)
		source_points = PackedVector3Array()  # Clear reference.
		state = State.IDLE


func _on_request_map_points(p_source_points: PackedVector3Array) -> void:
	source_points = p_source_points
	state = State.PROCESSING_REQUEST
