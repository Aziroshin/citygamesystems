extends Node3D
class_name Curve3DDebugHandleVisualizer


const default_in_handle_material := preload("./in_handle_material.tres")
const default_out_handle_material := preload("./out_handle_material.tres")
const default_tangent_material := preload("./tangent_material.tres")
var in_handle_material := default_in_handle_material.duplicate()
var out_handle_material := default_out_handle_material.duplicate()
var tangent_material := default_tangent_material.duplicate()
var tangent_meshes: Array[MeshInstance3D] = []
var in_handle_meshes: Array[MeshInstance3D] = []
var out_handle_meshes: Array[MeshInstance3D] = []
var in_point_multi_mesh := MultiMeshInstance3D.new()
var out_point_multi_mesh := MultiMeshInstance3D.new()
## If true, the handle visualization will get updated.
@export var curve_changed := true
@export var curve := Curve3D.new():
	set(p_value):
		curve_changed = true
		curve = p_value
## The (non-baked) point indexes that are supposed to be visualized. If [0] is
## -1, all points are visualized (default). If the array is empty, no points
## will be visualized.
## Any indexes which don't correspond to points on the curve will be skipped
## silently. Treat this as a "wishlist" of sorts of curve points you'd like to
## have visualized if they're found on the curve.
@export var visualized_indexes := [-1]


#func _get_tangent_profile2d() -> PackedVector2Array:
	#return PackedVector2Array([
		#Vector2(0.0, 0.1),
		#Vector2(0.0107844, 0.0260358),
		#Vector2(0.0260358, 0.0107844),
		#Vector2(0.1, 0.0),
		#Vector2(0.0260358, -0.0107844),
		#Vector2(0.0107844, -0.0260358),
		#Vector2(0.0, -0.1),
		#Vector2(-0.0107844, -0.0260358),
		#Vector2(-0.0260358, -0.0107844),
		#Vector2(-0.1, 0.0),
		#Vector2(-0.0260358, 0.0107844),
		#Vector2(-0.0107844, 0.0260358),
	#])


func _get_tangent_profile2d() -> PackedVector2Array:
	return PackedVector2Array([
		Vector2(0.0, 0.2),
		Vector2(0.005, 0.005),
		Vector2(0.2, 0.0),
		Vector2(0.005, -0.005),
		Vector2(0.0, -0.2),
		Vector2(-0.005, -0.005),
		Vector2(-0.2, 0.0),
		Vector2(-0.005, 0.005),
	])


func _create_handle_distal_point_mesh(
	p_radius: float,
	p_height: float,
	p_points: int,
	p_material: StandardMaterial3D
) -> MeshInstance3D:
	var mesh_instance3d := MeshInstance3D.new()
	var cylinder := Curve3DDebugFuncs.get_cylinder(p_radius, p_height, p_points, true)
	Curve3DDebugFuncs.align_forward(cylinder, Vector3.UP)
	Curve3DDebugFuncs.scale(cylinder, 0.1)
	mesh_instance3d.mesh = Curve3DDebugFuncs.create_array_mesh(cylinder)
	mesh_instance3d.mesh.surface_set_material(0, p_material)
	return mesh_instance3d


func _create_handle_out_point_mesh() -> MeshInstance3D:
	return _create_handle_distal_point_mesh(3.0, 2.0, 8, out_handle_material)


func _create_handle_in_point_mesh() -> MeshInstance3D:
	return _create_handle_distal_point_mesh(1.2, 4.0, 4, in_handle_material)


## Returns the number of elements in `.visualized_indexes`, or the value of
## `.curve.point_count` if [0] of `visualized_indexes` is `-1`.
func get_visualized_indexes_count() -> int:
	if len(visualized_indexes) > 0 and visualized_indexes[0] == -1:
		return curve.point_count
	else:
		return len(visualized_indexes)


# Set `p_curve` as the new curve and update the visualization based on it.
# If [0] of `p_visualized_indexes` is `-2`, the parameter will be
# ignored (default). `-1` means that all points will be visualized and an empty
# array means none will be.
func set_curve(
	p_curve: Curve3D,
	p_visualized_indexes := PackedInt64Array([-2])
) -> void:
	curve = p_curve
	if len(p_visualized_indexes) > 0 and not p_visualized_indexes[0] == -2:
		visualized_indexes = p_visualized_indexes


func remove_all_meshes():
	for tangent_mesh in tangent_meshes:
		remove_child(tangent_mesh)
	tangent_meshes.clear()
	
	for in_handle_mesh in in_handle_meshes:
		remove_child(in_handle_mesh)
	in_handle_meshes.clear()
	
	for out_handle_mesh in out_handle_meshes:
		remove_child(out_handle_mesh)
	out_handle_meshes.clear()


func _add_tangent_mesh(tangent_mesh: MeshInstance3D) -> void:
	tangent_meshes.append(tangent_mesh)
	add_child(tangent_mesh)

func _update_visualization() -> void:
	curve_changed = false
	remove_all_meshes()
	
	if curve.point_count < 1:
		return
	
	for idx in get_visualized_indexes_count():
		if idx > curve.point_count - 1:
			continue
		
		var transform_of_tangency: Transform3D
		if curve.point_count == 1:
			transform_of_tangency = Transform3D(Basis(), curve.get_point_position(idx))
		else:
			transform_of_tangency = curve.sample_baked_with_rotation(
				Curve3DDebugFuncs.get_closest_offset_on_curve_or_zero(
					curve,
					curve.get_point_position(idx)
				)
		)
		var tangent_mesh := Curve3DDebugMesh.new()
		# Since the tangent handle is not expected to bend, let's cut down its
		# resolution somewhat.
		tangent_mesh.curve.bake_interval = 100.0
		tangent_mesh.profile2d = _get_tangent_profile2d()
		_add_tangent_mesh(tangent_mesh)
		
		#------------
		#--- Tangent.
		var point_of_tangency: Vector3
		# Point "in" of `curve`.
		tangent_mesh.curve.add_point(curve.get_point_position(idx) + curve.get_point_in(idx))
		# `sample_baked_with_rotation` would error on a 1-point curve.
		if curve.point_count == 1:
			point_of_tangency = curve.get_point_position(0)
		else:
			point_of_tangency = transform_of_tangency.origin
		# Point of `curve`.
		# If the in-point is ZERO, `point_of_tangency` is the current idx
		# position in `curve`. If we wouldn't check here, we'd add the same
		# position twice in a row.
		if not curve.get_point_in(idx) == Vector3.ZERO:
			tangent_mesh.curve.add_point(point_of_tangency)
		# Point "out" of `curve`.
		# Check to avoid consecutive same-point, as with the in-point above.
		if not curve.get_point_out(idx) == Vector3.ZERO:
			tangent_mesh.curve.add_point(curve.get_point_position(idx) + curve.get_point_out(idx))
		# If both in and out points are ZERO, the tangent mesh will be empty.
		tangent_mesh.update()
		if tangent_mesh.mesh.get_surface_count() > 0:
			tangent_mesh.mesh.surface_set_material(0, tangent_material)
		
		#-------------
		#--- In point.
		var handle_in_point_mesh := _create_handle_in_point_mesh()
		if tangent_mesh.curve.point_count == 1:
			handle_in_point_mesh.transform = transform_of_tangency
		else:
			handle_in_point_mesh.transform = Curve3DDebugFuncs.get_point_transform(
				tangent_mesh.curve,
				0
			)
		in_handle_meshes.append(handle_in_point_mesh)
		add_child(handle_in_point_mesh)
		
		#--------------
		#--- Out point.
		var handle_out_point_mesh := _create_handle_out_point_mesh()
		if tangent_mesh.curve.point_count == 1:
			handle_out_point_mesh.transform = transform_of_tangency
		else:
			handle_out_point_mesh.transform = Curve3DDebugFuncs.get_point_transform(
				tangent_mesh.curve,
				tangent_mesh.curve.point_count - 1
			)
		out_handle_meshes.append(handle_out_point_mesh)
		add_child(handle_out_point_mesh)


func _process(_p_delta: float) -> void:
	if curve_changed:
		_update_visualization()
