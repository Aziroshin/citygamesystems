extends CityGameWorldObjectLifeCycler
class_name StreetSegmentWorldObjectLifeCycler

# Dependencies:
# CityBuilder.StreetSegment


func create(
	p_main_curve: Curve3D,
	p_radius: float,
	p_foundation_points: PackedVector3Array
) -> StreetSegmentWorldObject:
	return create_from_segment(CityBuilder.StreetSegment.new(
		p_main_curve,
		p_radius
	))


func _create_collider(
	p_segment: CityBuilder.StreetSegment,
	p_depth := 0.1
) -> CollisionObject3D:
	var collider := Area3D.new()
	var shape_provider := CollisionShape3D.new()
	var shape := ConcavePolygonShape3D.new()
	
	#================================
	# Top Surface
	var left_boundary_points_top := GeoFoo.get_offset_curve_points(
		p_segment.main_curve,
		p_segment.radius
	)
	var right_boundary_points_top := GeoFoo.get_offset_curve_points(
		p_segment.main_curve,
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
			2.8,
			0.04
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
