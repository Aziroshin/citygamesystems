@tool
extends Node3D
class_name Curve3DDebugVisualizer

### Dependencies:
# - Curve3DDebugFuncs

var curve_mesh := Curve3DDebugMesh.new()
var handle_meshes: Array[Curve3DDebugMesh] = []
var curve_changed := false
@export var curve := Curve3D.new():
	get:
		return curve
	set(p_value):
		curve = p_value
		curve_changed = true
@export var get_curve_by_signal := false


func _ready() -> void:
	add_child(curve_mesh)
	_update_curve_mesh()


func _update_curve_mesh():
	curve_mesh.update(curve)


func _add_handle_mesh(
	_point_pos: Transform3D,
	_in_pos: Vector3,
	_out_pos: Vector3
):
	var handle := Curve3DDebugMesh.new()
	handle_meshes.append(handle)


func _update_handles():
	var new_points_count := curve.point_count - len(handle_meshes)
	
	for i_new_point in new_points_count:
		var idx := curve.point_count + i_new_point - 1
		_add_handle_mesh(
			curve.sample_baked_with_rotation(
				Curve3DDebugFuncs.get_closest_offset_on_curve_or_zero(
					curve,
					curve.get_point_position(i_new_point)
				)
			),
			curve.get_point_in(i_new_point),
			curve.get_point_out(i_new_point)
		)


func _update_visualization() -> void:
	curve_changed = false
	_update_curve_mesh()
	_update_handles()


func _process(_p_delta: float) -> void:
	if curve_changed:
		_update_visualization()


func _on_curve_changed(p_curve: Curve3D) -> void:
	if get_curve_by_signal:
		curve = p_curve
			
