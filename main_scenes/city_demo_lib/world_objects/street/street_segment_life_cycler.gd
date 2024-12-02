extends CityGameWorldObjectLifeCycler
class_name StreetSegmentWorldObjectLifeCycler

# Dependencies:
# CityBuilder.StreetSegment


func create(
	p_main_curve: Curve3D,
	p_radius: float,
	_p_foundation_points: PackedVector3Array
) -> StreetSegmentWorldObject:
	return create_from_segment(CityBuilder.StreetSegment.new(
		p_main_curve,
		p_radius
	))


func _create_collider(
	p_segment: CityBuilder.StreetSegment,
	p_depth := 0.1
) -> CollisionObject3D:
	var collider := WorldObjectArea3D.new()
	var shape_provider := CollisionShape3D.new()
	var shape := ConcavePolygonShape3D.new()
	
	var segment_main_curve_baked_point_transforms := GeoFoo.get_baked_point_transforms(
		p_segment.main_curve
	)
	
	# =====
	# Debugging `GeoFoo.get_overlapping_offset_2d_curve_point_indexes`
	var overlapping_indexes := GeoFoo.get_overlapping_offset_2d_curve_point_indexes(
		segment_main_curve_baked_point_transforms,
		#-p_segment.radius,
		-p_segment.radius,
		collider
	)
	#for i in overlapping_indexes:
		#Cavedig.needle(
			#collider,
			#segment_main_curve_baked_point_transforms[i],
			#Vector3(1.0, 0.4, 0.4),
			#7.0,
			#0.02
		#)
	
	print("street_segment_life_cycler.gd, overlapping indexes: ", overlapping_indexes)
	print("test intersection result: ", Geometry2D.line_intersects_line(
		Vector2(1.0, 1.0),
		Vector2(0.0, 1.0),
		Vector2(-2.0, -2.0),
		Vector2(2.0, -4.0)
	))
	
	# Testing `Cavedig.needle_between`.
	var point_count := len(segment_main_curve_baked_point_transforms)
	Cavedig.needle_between(
		collider,
		segment_main_curve_baked_point_transforms[0].origin,
		segment_main_curve_baked_point_transforms[point_count-1].origin,
		Vector3(0.0, 0.9, 0.9),
		0.2
	)
	
	var offset_points := PackedVector3Array()
	var offset_forwards := PackedVector3Array()
	
	var i_debug := 0
	for transform in segment_main_curve_baked_point_transforms:
		var offset_point := transform.origin + transform.basis.x * -p_segment.radius
		
		var debug_scaling := 32.0  # Makes it easier to see when debug visualizing.
		var offset_forward := offset_point - transform.basis.z * 0.5 * debug_scaling
		
		var debug_color_good := Vector3(0.0, 1.0, 0.0)
		var debug_color_bad := Vector3(1.0, 0.0, 0.0)
		
		# Testing `Cavedig.needle_between`.
		Cavedig.needle_between(
			collider,
			offset_point + Vector3(0.0, 1.0, 0.0),
			offset_forward + Vector3(0.0, 1.0, 0.0),
			debug_color_bad if i_debug in overlapping_indexes else debug_color_good,
			0.005
		)
		
		
		Cavedig.needle(
			collider,
			Transform3D(Basis(), offset_point + Vector3(0.0, 1.0, 0.0)),
			Vector3(1.0, 0.0, 0.0),
			1.0,
			0.002
		)
		Cavedig.needle(
			collider,
			Transform3D(Basis(), offset_forward + Vector3(0.0, 1.0, 0.0)),
			Vector3(0.0, 0.0, 1.0),
			1.5,
			0.001
		)
		var line_mesh := MeshInstance3D.new()
		var line_size := 0.004
		var line_vertices := GeoFoo.get_loop_to_loop_extruded(
			PackedVector3Array([
				offset_point,
				offset_point+Vector3(0.0, line_size, 0.0),
				offset_point+Vector3(0.0, line_size, line_size)
			]),
			PackedVector3Array([
				offset_forward,
				offset_forward+Vector3(0.0, line_size, 0.0),
				offset_forward+Vector3(0.0, line_size, line_size)
			])
		)
		line_mesh.mesh = GeoFoo.create_array_mesh(line_vertices)
		line_mesh.transform.origin = line_mesh.transform.origin + Vector3(0.0, 0.5, 0.0)
		collider.add_child(line_mesh)
		
		offset_points.append(offset_point)
		offset_forwards.append(transform.basis.z)
		
		i_debug += 1
	# =====
	
	
	#================================
	# Top Surface
	var left_boundary_points_top := GeoFoo.get_offset_baked_curve_points(
		segment_main_curve_baked_point_transforms,
		p_segment.radius
	)
	var right_boundary_points_top := GeoFoo.get_offset_baked_curve_points(
		segment_main_curve_baked_point_transforms,
		-p_segment.radius
	)
	var top_surface := GeoFoo.get_tris_between_equal_lines(
		left_boundary_points_top,
		right_boundary_points_top
	)
	
	#================================
	# Bottom Surface
	var left_boundary_points_bottom := GeoFoo.get_translated(
		left_boundary_points_top,
		Vector3(0.0, -p_depth, 0.0)
	)
	var right_boundary_points_bottom := GeoFoo.get_translated(
		right_boundary_points_top,
		Vector3(0.0, -p_depth, 0.0)
	)
	var bottom_surface = GeoFoo.get_tris_between_equal_lines(
		left_boundary_points_bottom,
		right_boundary_points_bottom
	)
	
	#================================
	# Side
	var side := GeoFoo.get_loop_to_loop_extruded(
		left_boundary_points_top + GeoFoo.get_reversed(right_boundary_points_top),
		left_boundary_points_bottom + GeoFoo.get_reversed(right_boundary_points_bottom)
	)
	
	#================================
	# Putting it all together
	
	# Temporary debug visualization of point transforms.
	for i_baked in len(p_segment.main_curve.get_baked_points()):
		var staff := Cavedig.needle(
			collider,
			GeoFoo.get_baked_point_transform(
				p_segment.main_curve,
				i_baked
			).rotated_local(Vector3(0.0, 0.0, 1.0), PI/2),
			Vector3(0.2, 0.8, 0.8),
			p_segment.radius * 2.0,
			0.02
		)
		staff.transform.origin = (
			staff.transform.origin
			- p_segment.transform.origin
			+ Vector3(0.0, 2.0, 0.0)
		)

	#var shape_tris := PackedVector3Array(top_surface + side + bottom_surface)
	var shape_tris := PackedVector3Array(side)
	
	shape.set_faces(shape_tris)
	#shape_provider.transform = shape_provider.transform.rotated(Vector3(1.0, 0.0, 0.0), PI/2)
	shape_provider.shape = shape
	
	# y-offset for debugging.
	shape_provider.transform.origin = Vector3(0.0, 3.0, 0.0)
	
	collider.add_child(shape_provider)
	
	return collider


func create_from_segment(
	p_segment: CityBuilder.StreetSegment
) -> StreetSegmentWorldObject:
	var world_object := StreetSegmentWorldObject.new()
	world_object.street_segment = p_segment
	world_object.add_collider(_create_collider(world_object.street_segment))
	return world_object


# Misc notes:
#   Mesh(es) should be optional - a street segment could be represented by a
#   shader, for example. But the collision would still have to be there.
