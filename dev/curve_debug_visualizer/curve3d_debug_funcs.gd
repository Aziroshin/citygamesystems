extends RefCounted
class_name Curve3DDebugFuncs


# Returns the closest offset to `point_idx` or `0.0` if the offset is `NaN`.
# If the offset is `NaN`, it will also push an error.
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


# Returns the vertices for the tris between two vertex loops.
static func extrude_loop_to_loop(
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

# Transforms `p_vertices` according to `p_transform`.
# Also returns `p_vertices` for convenience.
static func get_in_place_transformed(
	p_vertices: PackedVector3Array,
	p_transform: Transform3D
) -> PackedVector3Array:
	for i_vertex in len(p_vertices):
		p_vertices[i_vertex] = p_transform.basis * p_vertices[i_vertex] + p_transform.origin
	return p_vertices


# Returns the transform of a (non-baked) point in a curve.
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


# Returns the transform of a baked point in a curve.
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
