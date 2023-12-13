extends MeshInstance3D
class_name Curve3DMesh

@export var profile3d := PackedVector3Array()
@export var cap2d := PackedVector2Array()
# The polygon which will be extruded along the curve. If left empty,
# it will default to a quad with a side length of 0.1.
@export var profile2d := PackedVector2Array():
	set(p_new_profile2d):
		profile2d = p_new_profile2d
		
		profile3d = PackedVector3Array()
		for vertex2d in p_new_profile2d:
			profile3d.append(Vector3(vertex2d.x, vertex2d.y, 0.0))
		
		cap2d = PackedVector2Array()
		for idx in Geometry2D.triangulate_polygon(p_new_profile2d):
			cap2d.append(p_new_profile2d[idx])
@export var material := Material
@export var curve := Curve3D.new()


# Returns the closest offset to `point_idx` or `0.0` if the offset is `NaN`.
# If the offset is `NaN`, it will also push an error.
func get_closest_offset_on_curve_or_zero(point_idx: int) -> float:
	var offset := curve.get_closest_offset(curve.get_point_position(point_idx))
	
	if is_nan(offset):
		if curve.point_count >= 2:
			if curve.get_point_position(0) == curve.get_point_position(1):
				push_error(
					"The first two point positions in the curve are equal, so "
					+ "the offset is 'NaN'. Will return '0.0' instead."
				)
			else:
				push_error(
					"The offset is 'NaN'. Will return '0.0' instead (note: "
					+ "This is not the \"the first 2 point positions in the "
					+ "curve are equal\" case)."
				)
		offset = 0.0
	
	return offset


func get_point_transform(idx: int) -> Transform3D:
	return curve.sample_baked_with_rotation(
		get_closest_offset_on_curve_or_zero(idx)
	)


func get_baked_point_transform(idx: int) -> Transform3D:
	return curve.sample_baked_with_rotation(
		get_closest_offset_on_curve_or_zero(idx)
	)


func get_cap3d(p_inverted: bool) -> PackedVector3Array:
	assert(len(cap2d) % 3 == 0)
	
	var vertices := PackedVector3Array()
	vertices.resize(len(cap2d))
	
	for i_tri in range(0, len(cap2d), 3):
		vertices[i_tri] = Vector3(cap2d[i_tri].x, cap2d[i_tri].y, 0.0)
		if p_inverted:
			vertices[i_tri+1] = Vector3(cap2d[i_tri+2].x, cap2d[i_tri+2].y, 0.0)
			vertices[i_tri+2] = Vector3(cap2d[i_tri+1].x, cap2d[i_tri+1].y, 0.0)
		else:
			vertices[i_tri+1] = Vector3(cap2d[i_tri+1].x, cap2d[i_tri+1].y, 0.0)
			vertices[i_tri+2] = Vector3(cap2d[i_tri+2].x, cap2d[i_tri+2].y, 0.0)
		
	return vertices


func get_in_place_transformed(
	p_vertices: PackedVector3Array,
	p_transform: Transform3D
) -> PackedVector3Array:
	for i_vertex in len(p_vertices):
		p_vertices[i_vertex]\
		= p_transform.basis * p_vertices[i_vertex] + p_transform.origin
		
	return p_vertices


func _update_from_vertices(
	p_vertices: PackedVector3Array
) -> void:
	var array_mesh: ArrayMesh = ArrayMesh.new()
	var surface_arrays := []
	surface_arrays.resize(ArrayMesh.ARRAY_MAX)
	surface_arrays[ArrayMesh.ARRAY_VERTEX] = p_vertices
	
	array_mesh.add_surface_from_arrays(
		Mesh.PRIMITIVE_TRIANGLES,
		surface_arrays
	)
	mesh = array_mesh
	material_override = load("res://dev/cavedig/cavedig_material.tres")


func extrude_loop_to_loop(
	p_from: PackedVector3Array,
	p_to: PackedVector3Array
) -> PackedVector3Array:
	assert(len(p_from) == len(p_to))
	
	var i_next_vertex := 0
	var loop_vertex_count := len(p_from)
	var vertices := PackedVector3Array([])
	
	for i_vertex in loop_vertex_count:
		if i_vertex == loop_vertex_count - 1:
			i_next_vertex = 0
		else:
			i_next_vertex = i_vertex + 1
			
		# Tri 1
		vertices.append(p_from[i_vertex])
		vertices.append(p_to[i_vertex])
		vertices.append(p_from[i_next_vertex])
		# Tri 2
		vertices.append(p_from[i_next_vertex])
		vertices.append(p_to[i_vertex])
		vertices.append(p_to[i_next_vertex])
	return vertices


func update(p_curve: Curve3D) -> void:
	curve = p_curve
	if curve.get_baked_length() < 2:
		return
	
	var point_loops: Array[PackedVector3Array] = []
	var vertices := PackedVector3Array()
	var baked_points := curve.get_baked_points()
	
	# Initialize `point_loops` with loops transformed along the curve.
	for i_baked in len(baked_points):
		var point_transform := get_baked_point_transform(i_baked)
		var current_loop := PackedVector3Array()
		
		for vertex in profile3d:
			var transformed_vertex\
			:= point_transform.basis * vertex + point_transform.origin
			
			current_loop.append(transformed_vertex)
			
		point_loops.append(current_loop)
	
	# Make first cap.
	vertices += get_in_place_transformed(
		get_cap3d(true),
		get_baked_point_transform(0)
	)
	
	# We're skipping the the last loop, as this is expecting a "next"
	# loop in order to work - the last loop will already have been integrated
	# by the iteration pertaining to its previous loop.
	for i_loop in len(point_loops) - 1:
		vertices\
		= vertices\
		+ extrude_loop_to_loop(point_loops[i_loop], point_loops[i_loop+1])
	
	# Make second cap:
	vertices += get_in_place_transformed(
		get_cap3d(false),
		get_baked_point_transform(len(baked_points)-1)
	)
	
	_update_from_vertices(vertices)


func _ready() -> void:
	if len(profile2d) == 0:
		profile2d = PackedVector2Array([
			Vector2(0.0, 0.0),
			Vector2(0.0, 0.1),
			Vector2(0., 0.1),
			Vector2(0.1, 0.0)
		])
	update(curve)
