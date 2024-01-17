extends RayCast3D
class_name StreetToolMapRayCaster

enum State {
	IDLE,
	PROCESSING_REQUEST
}
var state: State = State.IDLE
signal result_map_points(p_points: PackedVector3Array)
var source_points := PackedVector3Array()


func _physics_process(_p_delta: float) -> void:
	if state == State.PROCESSING_REQUEST:
		var map_points := PackedVector3Array()
		
		# This is nonsense, just for testing.
		for i_point in range(len(source_points)):
			map_points.append(source_points[i_point] + Vector3(
				1.0*i_point, 1.0*i_point, 1.0*i_point
			))
		
		result_map_points.emit(map_points)
		source_points = PackedVector3Array()  # Clear reference.
		state = State.IDLE


func _on_request_map_points(p_source_points: PackedVector3Array) -> void:
	source_points = p_source_points
	state = State.PROCESSING_REQUEST
