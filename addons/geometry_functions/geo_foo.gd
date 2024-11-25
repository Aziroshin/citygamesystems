extends EditorPlugin
class_name GeoFoo

class vector3:
	static func xy(p_xyz: Vector3) -> Vector2:
		return Vector2(p_xyz.x, p_xyz.y)

	static func xz (p_xyz: Vector3) -> Vector2:
		return Vector2(p_xyz.x, p_xyz.z)


class basis:
	static func get_subtracted(
		p_minuend: Basis,
		p_subtrahend: Basis
	) -> Basis:
		return Basis(
			p_minuend.x - p_subtrahend.x,
			p_minuend.y - p_subtrahend.y,
			p_minuend.z - p_subtrahend.z
		)
		
	static func get_added(
		p_a: Basis,
		p_b: Basis
	):
		return Basis(
			p_a.x + p_b.x,
			p_a.y + p_b.y,
			p_a.z + p_b.z
		)
		
	static func get_linearly_extrapolated(
		p_from: Basis,
		p_to: Basis
	) -> Basis:
		return get_added(p_to, get_subtracted(p_from, p_to))


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


## Returns `p_reference_point` if `p_points` is empty.
static func get_closest_point(
	p_reference_point: Vector3,
	p_points: PackedVector3Array
) -> Vector3:
	if len(p_points) == 0:
		return p_reference_point
	
	var closest_point_candidates_by_length: Dictionary = {}
	
	for closest_point_candidate in p_points:
		closest_point_candidates_by_length[
			(closest_point_candidate - p_reference_point).length()
		] = closest_point_candidate
	
	var shortest_length = closest_point_candidates_by_length.keys().reduce(
		func(shortest_so_far, prospective_length):
			return min(shortest_so_far, prospective_length)
	)
	return closest_point_candidates_by_length[shortest_length]


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


## Get a mesh made up of tris woven between two lines.
static func get_tris_between_equal_lines(
	p_from: PackedVector3Array,
	p_to: PackedVector3Array
) -> PackedVector3Array:
	assert(len(p_from) >= 2)
	assert(len(p_from) == len(p_to))
	
	var vertices := PackedVector3Array()
	
	var segment_count := (len(p_from) - 1)
	var vertex_count := segment_count * 6
	vertices.resize(vertex_count)
	for i_segment in range(0, segment_count):
		var i_first := i_segment * 6
		vertices[i_first] = p_from[i_segment]
		vertices[i_first+1] = p_from[i_segment+1]
		vertices[i_first+2] = p_to[i_segment]
		
		vertices[i_first+3] = p_from[i_segment+1]
		vertices[i_first+4] = p_to[i_segment+1]
		vertices[i_first+5] = p_to[i_segment]
	
	return vertices


## Convenience function to get a reversed duplicate `PackedVector3Array`.
static func get_reversed(p_array: PackedVector3Array) -> PackedVector3Array:
	var new_array := p_array.duplicate()
	new_array.reverse()
	return new_array


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
	p_curve: Curve3D,
	p_idx: int
) -> Transform3D:
	return p_curve.sample_baked_with_rotation(
		Curve3DDebugFuncs.get_closest_offset_on_curve_or_zero(
			p_curve,
			p_curve.get_point_position(p_idx)
		)
	)


# Note: There's a copy-paste of this function's body in
# `get_baked_point_transforms`. If there should ever be changes to this
# function, make sure to make changes there accordingly as well.
## Returns the transform of a baked point in a curve.
static func get_baked_point_transform(
	p_curve: Curve3D,
	p_idx: int
) -> Transform3D:
	return p_curve.sample_baked_with_rotation(
		get_closest_offset_on_curve_or_zero(
			p_curve,
			p_curve.get_baked_points()[p_idx]
		)
	)


static func get_baked_point_transforms(
	p_curve: Curve3D
) -> Array[Transform3D]:
	var transforms: Array[Transform3D] = []
	
	for idx in len(p_curve.get_baked_points()):
		transforms.append(
			# Copy-paste of `get_baked_point_transform` - saving on function
			# call overhead a bit, as there might potentially be a lot of points
			# to go through, and often.
			p_curve.sample_baked_with_rotation(
				get_closest_offset_on_curve_or_zero(
					p_curve,
					p_curve.get_baked_points()[idx]
				)
			)
		)
	return transforms


## Get the points of a `Curve3D` offset by the specified amount.
## If `curve_relative` is `false`, the resulting points will be global
## (default), otherwise they will be relative to the corresponding
## point in the curve.
static func get_offset_baked_curve_points(
	p_baked_point_transforms: Array[Transform3D],
	p_offset: float,
	curve_relative := false
) -> PackedVector3Array:
	var offset_points := PackedVector3Array()
	
	# BUG: Crash bug happens somewhere here; has to do something with 
	# `VariantSetGet_Transform3D_basis::validated_get`.
	for transform in p_baked_point_transforms:
		# Crash bug happens here.
		var offset_point := transform.basis.x * p_offset
		if curve_relative:
			offset_points.append(offset_point)
		else:
			offset_points.append(transform.origin + offset_point)
	# End of crash bug section.
	
	return offset_points


#static func get_offset_baked_curve_forward_points(
	#p_baked_point_transforms: Array[Transform3D],
	#p_offset_factor: float
#) -> PackedVector3Array:
	#var forward_points := PackedVector3Array()
	#for transform in p_baked_point_transforms:
		#forward_points.append(
			#
		#)

#
#static func get_inner_curve_offset_2d_overlaps(
	#p_,
	#p_transforms: Array[Transform3D]
#) -> PackedVector3Array:
	#for idx in range(0, len(p_transforms)):
		#var transform := p_transforms[idx]
		#var offset_forward := transform.origin + transform.basis.z


static func get_overlapping_offset_2d_curve_point_indexes(
	p_baked_point_transforms: Array[Transform3D],
	p_offset: float,
	p_debug_object: Node3D
) -> PackedInt64Array:
	var indexes := PackedInt64Array()
	var offset_points := PackedVector3Array()
	var offset_forwards := PackedVector3Array()
	
	for transform in p_baked_point_transforms:
		var offset_point := transform.origin + transform.basis.x * p_offset
		offset_points.append(offset_point)
		offset_forwards.append(-transform.basis.z * 0.1)
	
	
	Cavedig.needle(
		p_debug_object,
		Transform3D(Basis(), offset_points[0]),
		Vector3(0.4, 1.0, 0.2),
		6.5,
		0.006
	)
	
	var visited_indexes := 0
	var point_count := len(offset_points)
	for i_point in range(0, len(offset_points)):
		if i_point in indexes:
			continue
		
		var point_intersects := false
		for i_visited_point in range(visited_indexes + 1, point_count):
			var intersection_point_or_null = Geometry2D.line_intersects_line(
				vector3.xz(offset_points[i_point]),
				vector3.xz(offset_forwards[i_point]).normalized(),
				vector3.xz(offset_points[i_visited_point]),
				vector3.xz(offset_forwards[i_visited_point]).normalized()
			)
			
			# Guarding against parallels.
			if intersection_point_or_null == null:
				continue
			var intersection_point: Vector2 = intersection_point_or_null
			
			#print(
				#"intersection: ", intersection_point,
				#", i_poi: ", i_point,
				#", i_vis: ", i_visited_point,
				#", points(i_poi): ", GeoFoo.vector3.xz(offset_points[i_point]),
				#", points(i_vis): ", GeoFoo.vector3.xz(offset_points[i_visited_point]),
				#", forwards(i_poi): ", GeoFoo.vector3.xz(offset_forwards[i_point]).normalized(),
				#", forwards(i_vis)", GeoFoo.vector3.xz(-offset_forwards[i_visited_point]).normalized()
			#)
			#print("geo_food.gd: (normalized) intersection point: %s, forward: %s" % [
				#(intersection_point - GeoFoo.vector3.xz(offset_points[i_visited_point])).normalized(),
				#GeoFoo.vector3.xz(-offset_forwards[i_visited_point]).normalized()
			#])
			
			# Show which side it's processing.
			#Cavedig.needle(
				#p_debug_object,
				#Transform3D(Basis(), offset_points[i_point]),
				#Vector3(0.4, 1.0, 0.2),
				#6.5,
				#0.006
			#)
			
			var from_offset_to_intersection_point := intersection_point - GeoFoo.vector3.xz(
				offset_points[i_visited_point]
			)
			var offset_forward := GeoFoo.vector3.xz(offset_forwards[i_visited_point])
			if not from_offset_to_intersection_point.normalized()\
			.is_equal_approx(-offset_forward.normalized()):
			#if not from_offset_to_intersection_point.normalized().dot(-offset_forward.normalized()) == 1.0:
				#indexes.append(i_visited_point)
				point_intersects = true
				print(
					"geo_foo.gd, intersection@", intersection_point, " between ",
					"(%s)" % i_point, vector3.xz(offset_points[i_point]), " and ",
					"(%s)" % i_visited_point, vector3.xz(offset_points[i_visited_point])
				)
				Cavedig.needle(
					p_debug_object,
					Transform3D(Basis(), Vector3(intersection_point.x, 0.0, intersection_point.y)),
					Vector3(1.0, 0.4, 0.4),
					7.0,
					0.005
				)
				break
		if point_intersects:
			print("BAD: ", i_point)
			indexes.append(i_point)
		else:
			print("good: ", i_point)
		visited_indexes += 1
	
	return indexes


## Returns the vector from  the point at `p_idx` to the "out" position of the
## point at `p_idx - 1`.
## This assumes all checks have been done, e.g. that the curve has at least
## two points.
static func get_point_to_preceding_point_out(
	p_curve: Curve3D,
	p_idx: int,
	p_normalized := false,
	p_scale := 1.0
) -> Vector3:
	var preceding_idx := p_idx - 1
	var vector := (
		p_curve.get_point_position(preceding_idx)
		+ p_curve.get_point_out(preceding_idx)
		- p_curve.get_point_position(p_idx)
	)
	
	if p_normalized:
		vector = vector.normalized()
	
	return vector * p_scale


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


static func flip(p_vertices: PackedVector3Array) -> void:
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


## Returns the centroid (average) of the specified vertices.
## Returns `Vector3()` if no vertices are specified.
static func get_centroid(p_vertices: PackedVector3Array) -> Vector3:
	if len(p_vertices) == 0:
		return Vector3()
		
	var centroid := Vector3()
	for vertex in p_vertices:
		centroid += vertex
	centroid /= len(p_vertices)
	return centroid


#==========================================================================
# Vector converters
#==========================================================================

