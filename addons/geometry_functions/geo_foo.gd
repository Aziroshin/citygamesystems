extends EditorPlugin
class_name GeoFoo


func _enter_tree():
	pass


func _exit_tree():
	pass


static func create_array_mesh(
	p_vertices: PackedVector3Array
) -> ArrayMesh:
	var array_mesh: ArrayMesh = ArrayMesh.new()
	var surface_arrays := []
	surface_arrays.resize(ArrayMesh.ARRAY_MAX)
	surface_arrays[ArrayMesh.ARRAY_VERTEX] = p_vertices
	
	array_mesh.add_surface_from_arrays(
		Mesh.PRIMITIVE_TRIANGLES,
		surface_arrays
	)
	return array_mesh


## Returns the closest offset to `point_idx` or `0.0` if the offset is `NaN`.
## If the offset is `NaN`, it will also push an error.
static func get_closest_offset_on_curve_or_zero(
	curve: Curve3D,
	point_position: Vector3
) -> float:
	var offset := curve.get_closest_offset(point_position)
	
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


## Aligns `vertices` along the `new_forward` vector.
## For example: If you pass the result of the `to_3d` function, with
## `Vector3.FORWARD` passed to its `forward` parameter (the default), to this
## function, with `Vector3.UP` passed to the `new_forward` parameter, the result
## will be rotated by 90°, from the x,y plane to the x,z plane, since what was
## once looking "forward" to -z (Vector3.FORWARD) is now looking "forward" to
## +y (Vector3.UP).
static func align_forward(
	p_vertices: PackedVector3Array,
	p_new_forward: Vector3,
) -> void:
	var new_forward_basis := Basis.looking_at(p_new_forward.normalized(), Vector3.FORWARD)
	for i_vertex in len(p_vertices):
		p_vertices[i_vertex] = new_forward_basis * p_vertices[i_vertex]


static func translate(
	p_vertices: PackedVector3Array,
	p_target_position: Vector3
) -> void:
	for i_vertex in len(p_vertices):
		p_vertices[i_vertex] = p_vertices[i_vertex] + p_target_position


static func to_translated(
	p_vertices: PackedVector3Array,
	p_target_position: Vector3
) -> PackedVector3Array:
	translate(p_vertices, p_target_position)
	return p_vertices


static func get_translated(
	p_vertices: PackedVector3Array,
	p_target_position: Vector3
) -> PackedVector3Array:
	var vertices := PackedVector3Array()
	for vertex in p_vertices:
		vertices.append(vertex + p_target_position)
	return vertices


static func get_3d(
	p_vertices_2d: PackedVector2Array,
	p_forward: Vector3 = Vector3.FORWARD
) -> PackedVector3Array:
	var vertices_3d := PackedVector3Array()
	
	for vertex_2d in p_vertices_2d:
		vertices_3d.append(Vector3(vertex_2d.x, vertex_2d.y, 0.0))
	
	if not p_forward == Vector3.FORWARD:
		align_forward(vertices_3d, p_forward)
	
	return vertices_3d


static func get_ngon_2d(p_n: int, p_radius := 1.0) -> PackedVector2Array:
	var vertices := PackedVector2Array()
	
	var rad_per_n := 2*PI/p_n
	for i_vertex in p_n:
		vertices.append(Vector2(
			p_radius * sin(rad_per_n * i_vertex),
			p_radius * cos(rad_per_n * i_vertex)
		))
	
	return vertices


static func get_convex_triangulated_to_point_2d(
	p_vertices: PackedVector2Array,
	p_point := Vector2()
) -> PackedVector2Array:
	var tris := PackedVector2Array()
	
	var last_vertex_idx := len(p_vertices) - 1
	for i_vertex in len(p_vertices):
		tris.append(p_vertices[i_vertex])
		
		if i_vertex == last_vertex_idx:
			# On the last iteration, the first vertex is also the last.
			# It's a bit like a clock: 00:00 is at the same position as 24:00.
			tris.append(p_vertices[0])
		else:
			tris.append(p_vertices[i_vertex+1])
		
		tris.append(p_point)
		
	return tris


## Returns the vertices for the tris between two vertex loops.
static func get_loop_to_loop_extruded(
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


## Transforms `p_vertices` according to `p_transform`.
## Also returns `p_vertices` for convenience.
static func to_transformed(
	p_vertices: PackedVector3Array,
	p_transform: Transform3D
) -> PackedVector3Array:
	for i_vertex in len(p_vertices):
		p_vertices[i_vertex] = p_transform.basis * p_vertices[i_vertex] + p_transform.origin
	return p_vertices


## Returns the transform of a (non-baked) point in a curve.
static func get_point_transform(
	curve: Curve3D,
	idx: int
) -> Transform3D:
	return curve.sample_baked_with_rotation(
		Curve3DDebugFuncs.get_closest_offset_on_curve_or_zero(
			curve,
			curve.get_point_position(idx)
		)
	)


## Returns the transform of a baked point in a curve.
static func get_baked_point_transform(
	curve: Curve3D,
	idx: int
) -> Transform3D:
	return curve.sample_baked_with_rotation(
		Curve3DDebugFuncs.get_closest_offset_on_curve_or_zero(
			curve,
			curve.get_baked_points()[idx]
		)
	)


## Recalculates all `p_vertices` into the local space of `p_node3d`.
static func localize_to_node(p_vertices: PackedVector3Array, p_node: Node3D) -> void:
	for i_vertex in len(p_vertices):
		p_vertices[i_vertex] = p_node.to_local(p_vertices[i_vertex])


static func flip_tris(p_vertices: PackedVector3Array) -> void:
	assert(len(p_vertices) % 3 == 0)
	
	for i_vertex in range(0, len(p_vertices), 3):
		var tmp_vertex1 := p_vertices[i_vertex+1]
		p_vertices[i_vertex+1] = p_vertices[i_vertex+2]
		p_vertices[i_vertex+2] = tmp_vertex1


static func flip(p_vertices) -> void:
	for i_vertex in len(p_vertices):
		p_vertices[i_vertex] = p_vertices[i_vertex] * -1


static func scale(
	p_vertices: PackedVector3Array, 
	p_scale: float
) -> void:
	for i_vertex in len(p_vertices):
		p_vertices[i_vertex] = p_vertices[i_vertex] * p_scale

 
static func get_local_transform(transform: Transform3D, local_node: Node3D) -> Transform3D:
	return Transform3D(
		transform.basis,
		local_node.to_local(transform.origin)
	)


static func get_cylinder(
	p_radius := 1.0,
	p_height := 1.0,
	p_points := 8,
	z_centered := false
) -> PackedVector3Array:
	var vertices: PackedVector3Array
	
	var top_position := Vector3(0.0, 0.0, -p_height)
	var profile_2d := Curve3DDebugFuncs.get_ngon_2d(p_points, p_radius)
	var profile_3d := Curve3DDebugFuncs.get_3d(profile_2d)
	var bottom := Curve3DDebugFuncs.get_3d(
		Curve3DDebugFuncs.get_convex_triangulated_to_point_2d(profile_2d)
	)
	var wall := Curve3DDebugFuncs.get_loop_to_loop_extruded(
		profile_3d,
		Curve3DDebugFuncs.get_translated(profile_3d, top_position)
	)
	var top := bottom.duplicate()
	translate(top, top_position)
	flip_tris(top)
	
	vertices = bottom + wall + top
	if z_centered:
		translate(vertices, top_position/2)
	return vertices
